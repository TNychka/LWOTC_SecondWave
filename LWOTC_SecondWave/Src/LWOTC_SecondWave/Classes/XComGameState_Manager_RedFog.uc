class XComGameState_Manager_RedFog extends XComGameState_BaseObject;

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

`MCM_CH_VersionChecker(class'RedFogOptions_Defaults'.default.VERSION,class'RedFogOptionsListener'.default.CONFIG_VERSION)

function GetOptionsFromMenu()
{
	local string configString;

	EnabledAlien = `MCM_CH_GetValue(class'RedFogOptions_Defaults'.default.EnabledAlien,class'RedFogOptionsListener'.default.EnabledAlien);
	`REDSCREEN("Enabled Alien" $ EnabledAlien);
	EnabledXcom = `MCM_CH_GetValue(class'RedFogOptions_Defaults'.default.EnabledXcom,class'RedFogOptionsListener'.default.EnabledXcom);
	`REDSCREEN("Enabled XCOM" $ EnabledXcom);
	IsLinear = `MCM_CH_GetValue(class'RedFogOptions_Defaults'.default.IsLinear,class'RedFogOptionsListener'.default.IsLinear);
	`REDSCREEN("Enabled Linear" $ IsLinear);

	configString = `MCM_CH_GetValue(class'RedFogOptions_Defaults'.default.PenaltyType,class'RedFogOptionsListener'.default.PenaltyType);
	switch (configString)
	{
		case "Additive":
			PenaltyType = MODOP_Addition;
		case "Multiplicative":
			PenaltyType = MODOP_Multiplication;
		default:
			PenaltyType = MODOP_Addition;
	}

	configString = `MCM_CH_GetValue(class'RedFogOptions_Defaults'.default.HealingType,class'RedFogOptionsListener'.default.HealingType);
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

function RegisterManager() {
	local object ThisObj;

	ThisObj = self;
	`XEVENTMGR.RegisterForEvent(ThisObj, 'OnUnitBeginPlay', OnPostInitAbilities, ELD_OnStateSubmitted, 30,, true);
	`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_HealthWatcher);
}

//register to receive new gamestates in order to update RedFog whenever HP changes on a unit, and in tactical
static function OnNewGameState_HealthWatcher(XComGameState GameState)
{
	local XComGameState NewGameState;
	local int StateObjectIndex;
	local XComGameState_Effect RedFogEffect;
	local XComGameState_Effect_RedFog RFEComponent;
	local XComGameState_Unit HPChangedUnit, UpdatedUnit;
	local array<XComGameState_Unit> HPChangedObjects;  // is generically just a pair of XComGameState_BaseObjects, pre and post the change

	if(`TACTICALRULES == none || !`TACTICALRULES.TacticalGameIsInPlay()) return; // only do this checking when in tactical battle

	HPChangedObjects.Length = 0;
	GetHPChangedObjectList(GameState, HPChangedObjects);
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update RedFog OnNewGameState_HealthWatcher");
	for( StateObjectIndex = 0; StateObjectIndex < HPChangedObjects.Length; ++StateObjectIndex )
	{	
		HPChangedUnit = HPChangedObjects[StateObjectIndex];
		if(HPChangedUnit.IsUnitAffectedByEffectName(class'X2Effect_RedFog'.default.EffectName))
		{
			RedFogEffect = HPChangedUnit.GetUnitAffectedByEffectState(class'X2Effect_RedFog'.default.EffectName);
			if(RedFogEffect != none)
			{
				RFEComponent = XComGameState_Effect_RedFog(RedFogEffect.FindComponentObject(class'XComGameState_Effect_RedFog'));
				if(RFEComponent != none)
				{
					UpdatedUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', HPChangedUnit.ObjectID));
					NewGameState.AddStateObject(UpdatedUnit);
					RFEComponent.UpdateRedFogPenalties(UpdatedUnit, NewGameState);
				}
			}
		}
	}
	if(NewGameState.GetNumGameStateObjects() > 0)
		`TACTICALRULES.SubmitGameState(NewGameState);
	else
		`XCOMHISTORY.CleanupPendingGameState(NewGameState);
}

static function GetHPChangedObjectList(XComGameState NewGameState, out array<XComGameState_Unit> OutHPChangedObjects)
{
	local XComGameStateHistory History;
	local int StateObjectIndex;
	local XComGameState_BaseObject StateObjectCurrent;
	local XComGameState_BaseObject StateObjectPrevious;
	local XComGameState_Unit UnitStateCurrent, UnitStatePrevious;

	History = `XCOMHISTORY;

    for( StateObjectIndex = 0; StateObjectIndex < NewGameState.GetNumGameStateObjects(); ++StateObjectIndex )
	{
		StateObjectCurrent = NewGameState.DebugGetGameStateForObjectIndex(StateObjectIndex);		
		UnitStateCurrent = XComGameState_Unit(StateObjectCurrent);
		if( UnitStateCurrent != none )
		{
			StateObjectPrevious = History.GetGameStateForObjectID(StateObjectCurrent.ObjectID, , NewGameState.HistoryIndex - 1);
			UnitStatePrevious = XComGameState_Unit(StateObjectPrevious);

			if(UnitStatePrevious != none && UnitStateCurrent.GetCurrentStat(eStat_HP) != UnitStatePrevious.GetCurrentStat(eStat_HP))
			{
				OutHPChangedObjects.AddItem(UnitStateCurrent);
			}
		}
	}
}

function EventListenerReturn OnPostInitAbilities(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameStateHistory History;
	local XComGameStateContext_ChangeContainer ChangeContainer;
	local XComGameState_Unit UnitState, UpdatedUnitState;
	local bool UnitNeedsRedFog;

	History = `XCOMHISTORY;

	//`TBTRACE("OnAddRedFogAbility : OnUnitBeginPlay triggered.",, 'LW_Toolbox');
	UnitState = XComGameState_Unit(EventData);
	if(UnitState != none)
	{
		UnitNeedsRedFog = !UnitState.IsSoldier();
		if (UnitNeedsRedFog)
		{
			ChangeContainer = class'XComGameStateContext_ChangeContainer'.static.CreateEmptyChangeContainer("Applying Red Fog to specific unit");
			NewGameState = History.CreateNewGameState(true, ChangeContainer);
			UpdatedUnitState = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
			AddRedFogAbilityToOneUnit(UpdatedUnitState, NewGameState);
			NewGameState.AddStateObject(UpdatedUnitState);
			`GAMERULES.SubmitGameState(NewGameState);
		}
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
	RedFogAbilityTemplate = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager().FindAbilityTemplate('RedFog_LW');

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
		}
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

// Get instance of manager
static function XComGameState_Manager_RedFog GetRedFogManager()
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(CampaignSettingsStateObject != none)
		return XComGameState_Manager_RedFog(CampaignSettingsStateObject.FindComponentObject(class'XComGameState_Manager_RedFog'));
	return none;
}

// Initializers
function static XComGameState_Manager_RedFog CreateModSettingsState_NewCampaign(XComGameState GameState)
{
	local XComGameState_Manager_RedFog ManagerState;
	local bool bFoundExistingSettings;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	foreach GameState.IterateByClassType(class'XComGameState_CampaignSettings', CampaignSettingsStateObject)
	{
		break;
	}
	//check for existing ModOptions game state -- this should never happen here, but keeping the code intact just in case
	if(CampaignSettingsStateObject != none)
	{
		if(CampaignSettingsStateObject.FindComponentObject(class'XComGameState_Manager_RedFog', false) != none)
			bFoundExistingSettings = true;
	}
	if(CampaignSettingsStateObject == none || bFoundExistingSettings)
	{
	}
	else
	{
		CampaignSettingsStateObject = XComGameState_CampaignSettings(GameState.CreateStateObject(class'XComGameState_CampaignSettings', CampaignSettingsStateObject.ObjectID));
		ManagerState = XComGameState_Manager_RedFog(GameState.CreateStateObject(class'XComGameState_Manager_RedFog'));
		ManagerState.GetOptionsFromMenu();
		CampaignSettingsStateObject.AddComponentObject(ManagerState);
		GameState.AddStateObject(ManagerState);
		GameState.AddStateObject(CampaignSettingsStateObject);
		return ManagerState;
	}
	return none;
}

function static XComGameState_Manager_RedFog CreateModSettingsState_ExistingCampaign()
{
	local XComGameState_Manager_RedFog ManagerState;
	local bool bFoundExistingSettings;
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState UpdateState;

	History = `XCOMHISTORY;
	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Red Fog Manager");
	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	//check for existing ModOptions game state
	if(CampaignSettingsStateObject != none)
	{
		if(CampaignSettingsStateObject.FindComponentObject(class'XComGameState_Manager_RedFog', false) != none)
			bFoundExistingSettings = true;
	}
	if(CampaignSettingsStateObject == none || bFoundExistingSettings)
	{
		History.CleanupPendingGameState(UpdateState);
	}
	else
	{
		CampaignSettingsStateObject = XComGameState_CampaignSettings(UpdateState.CreateStateObject(class'XComGameState_CampaignSettings', CampaignSettingsStateObject.ObjectID));
		ManagerState = XComGameState_Manager_RedFog(UpdateState.CreateStateObject(class'XComGameState_Manager_RedFog'));
		ManagerState.GetOptionsFromMenu();
		CampaignSettingsStateObject.AddComponentObject(ManagerState);
		UpdateState.AddStateObject(ManagerState);
		UpdateState.AddStateObject(CampaignSettingsStateObject);
		History.AddGameStateToHistory(UpdateState);
		return ManagerState;
	}
	return none;
}