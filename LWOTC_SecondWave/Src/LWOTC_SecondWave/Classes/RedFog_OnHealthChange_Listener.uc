class RedFog_OnHealthChange_Listener extends Object;

//register to receive new gamestates in order to update RedFog whenever HP changes on a unit, and in tactical
static function OnNewGameState_HealthWatcher(XComGameState GameState)
{
	local XComGameState NewGameState;
	local int StateObjectIndex;
	local XComGameState_Effect RedFogEffect;
	local RedFog_XComGameState_Effect RFEComponent;
	local XComGameState_Unit HPChangedUnit, UpdatedUnit;
	local array<XComGameState_Unit> HPChangedObjects;  // is generically just a pair of XComGameState_BaseObjects, pre and post the change

	if(`TACTICALRULES == none || !`TACTICALRULES.TacticalGameIsInPlay()) return; // only do this checking when in tactical battle

	HPChangedObjects.Length = 0;
	GetHPChangedObjectList(GameState, HPChangedObjects);
	
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update RedFog OnNewGameState_HealthWatcher");
	for( StateObjectIndex = 0; StateObjectIndex < HPChangedObjects.Length; ++StateObjectIndex )
	{	
		HPChangedUnit = HPChangedObjects[StateObjectIndex];
		if(HPChangedUnit.IsUnitAffectedByEffectName(class'RedFog_X2Effect'.default.EffectName))
		{
			RedFogEffect = HPChangedUnit.GetUnitAffectedByEffectState(class'RedFog_X2Effect'.default.EffectName);
			if(RedFogEffect != none)
			{
				RFEComponent = RedFog_XComGameState_Effect(RedFogEffect.FindComponentObject(class'RedFog_XComGameState_Effect'));
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