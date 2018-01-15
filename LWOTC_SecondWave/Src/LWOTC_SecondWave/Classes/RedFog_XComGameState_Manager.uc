class RedFog_XComGameState_Manager extends XComGameState_Manager_LWOTC;

`include(LWOTC_SecondWave/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

enum ERedFogHealingType
{
	eRFHealing_Undefined,
	eRFHealing_CurrentHP,
	eRFHealing_LowestHP,
	eRFHealing_AverageHP,
};

var bool EnabledAlien;
var bool EnabledXcom;
var bool IsLinear;
var EStatModOp PenaltyType;
var ERedFogHealingType HealingType;

`MCM_CH_VersionChecker(class'ModMenu_Options_Defaults'.default.VERSION,class'ModMenu_Options_Listener'.default.CONFIG_VERSION)

static function RedFog_XComGameState_Manager GetRedFogManager()
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(CampaignSettingsStateObject != none)
		return RedFog_XComGameState_Manager(CampaignSettingsStateObject.FindComponentObject(class'RedFog_XComGameState_Manager'));
	return none;
}

event OnCreation(optional X2DataTemplate InitTemplate)
{
	local string configString;

	EnabledAlien = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.RedFog_EnabledAlien,class'ModMenu_Options_Listener'.default.RedFog_EnabledAlien);
	EnabledXcom = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.RedFog_EnabledXcom,class'ModMenu_Options_Listener'.default.RedFog_EnabledXcom);
	IsLinear = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.RedFog_IsLinear,class'ModMenu_Options_Listener'.default.RedFog_IsLinear);

	configString = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.RedFog_PenaltyType,class'ModMenu_Options_Listener'.default.RedFog_PenaltyType);
	switch (configString)
	{
		case "Additive":
			PenaltyType = MODOP_Addition;
		case "Multiplicative":
			PenaltyType = MODOP_Multiplication;
		default:
			PenaltyType = MODOP_Addition;
	}

	configString = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.RedFog_HealingType,class'ModMenu_Options_Listener'.default.RedFog_HealingType);
	switch (configString)
	{
		case "Current HP":
			HealingType = eRFHealing_CurrentHP;
		case "Average HP":
			HealingType = eRFHealing_AverageHP;
		case "Lowest HP":
			HealingType = eRFHealing_LowestHP;
		default:
			HealingType = eRFHealing_Undefined;
	}
}

function RegisterManager()
{
	local object ThisObj;

	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'OnUnitBeginPlay', OnPostInitAbilities, ELD_OnStateSubmitted, 30,, true);
	`XCOMHISTORY.RegisterOnNewGameStateDelegate(class'RedFog_OnHealthChange_Listener'.static.OnNewGameState_HealthWatcher);
}

function EventListenerReturn OnPostInitAbilities(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_Unit UnitState, UpdatedUnitState;

	History = `XCOMHISTORY;

	UnitState = XComGameState_Unit(EventData);
	if(UnitState != none)
	{
		ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Applying Red Fog to specific unit");
		NewGameState = History.CreateNewGameState(true, ChangeContainer);
		UpdatedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		AddRedFogAbilityToOneUnit(UpdatedUnitState, NewGameState);
		NewGameState.AddStateObject(UpdatedUnitState);
		`GAMERULES.SubmitGameState(NewGameState);
	}
	else
	{
		`REDSCREEN("OnAddRedFogAbility : Event Triggered without valid Unit EventData");
	}
	return ELR_NoInterrupt;
}

function AddRedFogAbilityToOneUnit(XComGameState_Unit AbilitySourceUnitState, XComGameState GameState)
{
	local X2AbilityTemplate RedFogAbilityTemplate, AbilityTemplate;
	local array<X2AbilityTemplate> AllAbilityTemplates;
	local StateObjectReference AbilityRef;
	local XComGameState_Ability AbilityState;
	local Name AdditionalAbilityName;
	local X2EventManager EventMgr;

	EventMgr = `XEVENTMGR;
	RedFogAbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('RedFog');

	if( RedFogAbilityTemplate != none )
	{
		AllAbilityTemplates.AddItem(RedFogAbilityTemplate);
		foreach RedFogAbilityTemplate.AdditionalAbilities(AdditionalAbilityName)
		{
			AbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate(AdditionalAbilityName);
			if( AbilityTemplate != none )
			{
				AllAbilityTemplates.AddItem(AbilityTemplate);
			}
			else
			{
				`REDSCREEN("OnAddRedFogAbility : Could not find ability " $ AdditionalAbilityName);
			}
		}
	}
	else
	{
		`REDSCREEN("OnAddRedFogAbility : Could not find ability RedFog");
	}
	

	if(AbilitySourceUnitState.GetTeam() != eTeam_XCom && AbilitySourceUnitState.GetTeam() != eTeam_Alien)
		return;

	AbilitySourceUnitState = XComGameState_Unit(GameState.CreateStateObject(class'XComGameState_Unit', AbilitySourceUnitState.ObjectID));
	GameState.AddStateObject(AbilitySourceUnitState);

	foreach AllAbilityTemplates(AbilityTemplate)
	{
		AbilityRef = AbilitySourceUnitState.FindAbility(AbilityTemplate.DataName);
		if( AbilityRef.ObjectID == 0 )
		{
			AbilityRef = `TACTICALRULES.InitAbilityForUnit(RedFogAbilityTemplate, AbilitySourceUnitState, GameState);
		}

		AbilityState = XComGameState_Ability(GameState.CreateStateObject(class'XComGameState_Ability', AbilityRef.ObjectID));
		GameState.AddStateObject(AbilityState);
	}

	// trigger event listeners now to update red fog activation for already applied effects
	EventMgr.TriggerEvent('UpdateRedFogActivation', self, AbilitySourceUnitState, GameState);
}
