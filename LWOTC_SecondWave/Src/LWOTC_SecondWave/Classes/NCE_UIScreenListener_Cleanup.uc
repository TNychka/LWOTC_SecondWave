//---------------------------------------------------------------------------------------
//  FILE:    NCE_UIScreenListener_Cleanup
//  AUTHOR:  Amineri / Long War Studios
//
//  PURPOSE: Performs garbage collection on gamestates when dismissing units
//--------------------------------------------------------------------------------------- 

class NCE_UIScreenListener_Cleanup extends UIScreenListener;

defaultproperties
{
	// Leaving this assigned to none will cause every screen to trigger its signals on this class
	ScreenClass = UIArmory_MainMenu;
}

// This event is triggered when a screen is removed
event OnRemoved(UIScreen Screen)
{
	//garbage collect officer states in case one was dismissed
	RandomizedStatsGCandValidationChecks();
}

function RandomizedStatsGCandValidationChecks()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit UnitState, UpdatedUnit;
	local NCE_XComGameState_RandomizedUnit RandomizedState, UpdatedRandomized;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("RandomizedStats States cleanup");
	foreach History.IterateByClassType(class'NCE_XComGameState_RandomizedUnit', RandomizedState,,true)
	{
		//check and see if the OwningObject is still alive and exists
		if(RandomizedState.OwningObjectId > 0)
		{
			UnitState = XComGameState_Unit(History.GetGameStateForObjectID(RandomizedState.OwningObjectID));
			if(UnitState == none)
			{
				// Remove disconnected officer state
				NewGameState.RemoveStateObject(RandomizedState.ObjectID);
			}
			else
			{
				if(UnitState.bRemoved)
				{
					UpdatedUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
					UpdatedRandomized = NCE_XComGameState_RandomizedUnit(NewGameState.CreateStateObject(class'NCE_XComGameState_RandomizedUnit', RandomizedState.ObjectID));
					NewGameState.RemoveStateObject(UpdatedRandomized.ObjectID);
					UpdatedUnit.RemoveComponentObject(UpdatedRandomized);
					NewGameState.AddStateObject(UpdatedRandomized);
					NewGameState.AddStateObject(UpdatedUnit);
				}
			}
		}
	}
	if (NewGameState.GetNumGameStateObjects() > 0)
		`GAMERULES.SubmitGameState(NewGameState);
	else
		History.CleanupPendingGameState(NewGameState);
}