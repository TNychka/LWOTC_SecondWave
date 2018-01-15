//---------------------------------------------------------------------------------------
//  FILE:    RedFog_X2Effect.uc
//  AUTHOR:  Amineri / Long War Studios
//	PURPOSE: Implements Red Fog, which decreases stats based on damage taken 
//---------------------------------------------------------------------------------------
class RedFog_X2Effect extends X2Effect_ModifyStats config(LWOTC_SecondWave_RedFog);

struct RedFogPenalty
{
	var ECharStatType Stat;
	var float InitialRate;
	var float MaxPenalty;
};

var config array<name> TypesImmuneToRedFog;
var config array<name> TypesHalfImmuneToRedFog;

var config array<RedFogPenalty> LinearRedFogPenalties;
var config array<RedFogPenalty> QuadraticRedFogPenalties;

var localized string RedFogEffectName;
var localized string RedFogEffectDesc;

defaultproperties
{
    DuplicateResponse=eDupe_Ignore
	EffectName="RedFog";
	bRemoveWhenSourceDies=true;
}

//add a component to XComGameState_Effect to track cumulative number of attacks
simulated protected function OnEffectAdded(const out EffectAppliedData ApplyEffectParameters, XComGameState_BaseObject kNewTargetState, 
	XComGameState NewGameState, XComGameState_Effect NewEffectState)
{
	local RedFog_XComGameState_Effect RFEffectState;
	local XComGameState_Unit TargetUnit;
	local RedFog_XComGameState_Manager RedFogManager;

	RedFogManager = class'RedFog_XComGameState_Manager'.static.GetRedFogManager();
	TargetUnit = XComGameState_Unit(kNewTargetState);
	if(TargetUnit == none)
		`REDSCREEN("RedFog_X2Effect : No target unit");

	RFEffectState = GetRedFogComponent(NewEffectState);
	if (RFEffectState == none)
	{
		//create component and attach it to GameState_Effect, adding the new state object to the NewGameState container
		RFEffectState = RedFog_XComGameState_Effect(NewGameState.CreateStateObject(class'RedFog_XComGameState_Effect'));
		RFEffectState.InitComponent();
		if(TargetUnit != none)
		{
			if (`SecondWaveEnabled('RedFog'))
			{
				if((TargetUnit.GetTeam() == eTeam_XCom && RedFogManager.EnabledXcom) || (TargetUnit.GetTeam() == eTeam_Alien && RedFogManager.EnabledAlien))
				{
					RFEffectState.bIsActive = true;
					//RFEffectState.RegisterEvents(TargetUnit);
				}
				else
				{
					RFEffectState.bIsActive = false;
					//RFEffectState.UnregisterEvents();
				}
			}
		}
		NewEffectState.AddComponentObject(RFEffectState);
		NewGameState.AddStateObject(RFEffectState);
	}

	//add listener to new component effect -- do it here because the RegisterForEvents call happens before OnEffectAdded, so component doesn't yet exist
	RFEffectState.RegisterEvent(TargetUnit);
}

function bool IsEffectCurrentlyRelevant(XComGameState_Effect EffectGameState, XComGameState_Unit TargetUnit)
{
	local RedFog_XComGameState_Effect RFEffectState;
	local bool Relevant;


	RFEffectState = GetRedFogComponent(EffectGameState);
	Relevant = (RFEffectState.ComputePctHPLost(TargetUnit) > 0.0f) && RFEffectState.bIsActive;
	// `TBTRACE("RedFog_X2Effect: Unit=" $ TargetUnit.GetFullName() $ ", Relevant=" $ Relevant $ ", PctLost=" $ RFEffectState.ComputePctHPLost(TargetUnit),, 'LW_Toolbox');
	return Relevant;
	//  Only relevant if we successfully rolled any stat changes
	//return EffectGameState.StatChanges.Length > 0;
}

simulated function OnEffectRemoved(const out EffectAppliedData ApplyEffectParameters, XComGameState NewGameState, bool bCleansed, XComGameState_Effect RemovedEffectState)
{
	local XComGameState_BaseObject EffectComponent;
	local Object EffectComponentObj;
	
	super.OnEffectRemoved(ApplyEffectParameters, NewGameState, bCleansed, RemovedEffectState);

	EffectComponent = GetRedFogComponent(RemovedEffectState);
	if (EffectComponent == none)
		return;

	EffectComponentObj = EffectComponent;
	`XEVENTMGR.UnRegisterFromAllEvents(EffectComponentObj);

	NewGameState.RemoveStateObject(EffectComponent.ObjectID);
}

static function RedFog_XComGameState_Effect GetRedFogComponent(XComGameState_Effect Effect)
{
	if (Effect != none) 
		return RedFog_XComGameState_Effect(Effect.FindComponentObject(class'RedFog_XComGameState_Effect'));
	return none;
}

