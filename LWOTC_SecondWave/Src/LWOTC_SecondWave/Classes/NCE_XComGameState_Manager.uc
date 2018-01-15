class NCE_XComGameState_Manager extends XComGameState_Manager_LWOTC;

function RegisterManager()
{
		local X2EventManager EventManager;
		local Object ThisObj;

		EventManager = `XEVENTMGR;
		ThisObj = self;

		//end of month handling of new recruits at Resistance HQ
		EventManager.RegisterForEvent( ThisObj, 'OnMonthlyReportAlert', OnMonthEnd, ELD_OnStateSubmitted,,,true); 
		//handles reward soldier creation, both for missions and purchase-able
		EventManager.RegisterForEvent( ThisObj, 'SoldierCreatedEvent', OnSoldierCreatedEvent, ELD_OnStateSubmitted,,,true);
		// Cleanup on dismiss
		EventManager.RegisterForEvent(ThisObj, 'OnDismissSoldier', CleanUpComponentStateOnDismiss, ELD_OnStateSubmitted,,,true);
}

function EventListenerReturn OnSoldierCreatedEvent(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit Unit;
	local XComGameState NewGameState;

	Unit = XComGameState_Unit(EventData);
	if(Unit == none) 
	{
		`REDSCREEN("LWOTC Second Wave OnSoldierCreatedEvent with no UnitState EventData");
		return ELR_NoInterrupt;
	}

	if(!GameState.bReadOnly)
	{
		UpdateOneSoldier(Unit, GameState);
	}
	else 	// when read-only we need to create and submit our own gamestate
	{
		//Build GameState change container
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Randomized Initial Stats");
		UpdateOneSoldier(Unit, NewGameState);

		if (`TACTICALRULES.TacticalGameIsInPlay())
		{	
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
		else
		{
			`GAMERULES.SubmitGameState(NewGameState);
		}
	}

	return ELR_NoInterrupt;
}

function EventListenerReturn OnMonthEnd(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState NewGameState;

	if(!GameState.bReadOnly)
	{
		UpdateAllSoldiers(GameState);
	}
	else 	// when read-only we need to create and submit our own gamestate
	{
		//Build GameState change container
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Randomized Initial Stats");
		UpdateAllSoldiers(NewGameState);

		if (`TACTICALRULES.TacticalGameIsInPlay())
		{	
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
		else
		{
			`GAMERULES.SubmitGameState(NewGameState);
		}
	}
	return ELR_NoInterrupt;
}

function UpdateSoldiers_GameStart(optional XComGameState NewGameState)
{
	local bool NeedsSubmit;

	NeedsSubmit = NewGameState == none;

	//Build GameState change container
	if(NeedsSubmit)
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Randomized Initial Stats");
	
	UpdateAllSoldiers(NewGameState);

	if(NeedsSubmit)
	{
		if (`TACTICALRULES.TacticalGameIsInPlay())
		{	
			`TACTICALRULES.SubmitGameState(NewGameState);
		}
		else
		{
			`GAMERULES.SubmitGameState(NewGameState);
		}
	}
}

function UpdateAllSoldiers(XComGameState GameState)
{
	local XComGameStateHistory History;
	local XComGameState StrategyState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_Unit Unit, StrategyUnit; 
	local int LastStrategyStateIndex;
	local array<StateObjectReference> UnitsInPlay;

	History = `XCOMHISTORY;

	foreach History.IterateByClassType(class'XComGameState_Unit', Unit,, true)
	{
		if(Unit.IsSoldier())
		{
			UnitsInPlay.AddItem(Unit.GetReference());
			UpdateOneSoldier(Unit, GameState);
		}
	}
	if (`TACTICALRULES.TacticalGameIsInPlay())
	{
		`REDSCREEN("All soldier update in tactical game, please report this error");

		// grab the archived strategy state from the history and the headquarters object
		LastStrategyStateIndex = History.FindStartStateIndex() - 1;
		StrategyState = History.GetGameStateFromHistory(LastStrategyStateIndex, eReturnType_Copy, false);
		foreach StrategyState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
		{
			break;
		}
		//XComHQ = `XCOMHQ;
		if(XComHQ == none)
		{
			`Redscreen("UpdateAllSoldiers_RandomizedInitialStats: Could not find an XComGameState_HeadquartersXCom state in the archive!");
		}

		if(LastStrategyStateIndex > 0)
		{
			foreach StrategyState.IterateByClassType(class'XComGameState_Unit', StrategyUnit)
			{

				// must be a soldier (not randomizing Bradford, Tygan and Shen)
				if (!StrategyUnit.IsSoldier())
					continue;

				// only if not already on the board
				if(UnitsInPlay.Find('ObjectID', StrategyUnit.ObjectID) != INDEX_NONE)
					continue;

				UpdateOneSoldier(StrategyUnit, GameState);
			}
		}
	}
}

function UpdateOneSoldier(XComGameState_Unit Unit, XComGameState GameState)
{
	local XComGameState_Unit UpdatedUnit;
	local NCE_XComGameState_RandomizedUnit RandomizedStatsState, SearchRandomizedStats;

	UpdatedUnit = XComGameState_Unit(GameState.GetGameStateForObjectID(Unit.ObjectID));
	if(UpdatedUnit == none || UpdatedUnit.bReadOnly)
	{
		UpdatedUnit = XComGameState_Unit(GameState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
		GameState.AddStateObject(UpdatedUnit);
	}

	if(GameState != none)
	{
		//first look in the supplied gamestate
		foreach GameState.IterateByClassType(class'NCE_XComGameState_RandomizedUnit', SearchRandomizedStats)
		{
			if(SearchRandomizedStats.OwningObjectID == Unit.ObjectID)
			{
				RandomizedStatsState = SearchRandomizedStats;
				break;
			}
		}
	}
	if(RandomizedStatsState == none)
	{
		//try and pull it from the history
		RandomizedStatsState = NCE_XComGameState_RandomizedUnit(Unit.FindComponentObject(class'NCE_XComGameState_RandomizedUnit'));
		if(RandomizedStatsState != none)
		{
			//if found in history, create an update copy for submission
			RandomizedStatsState = NCE_XComGameState_RandomizedUnit(GameState.CreateStateObject(RandomizedStatsState.Class, RandomizedStatsState.ObjectID));
			GameState.AddStateObject(RandomizedStatsState);
		}
	}
	if(RandomizedStatsState == none)
	{
		//first time randomizing, create component gamestate and attach it
		RandomizedStatsState = NCE_XComGameState_RandomizedUnit(GameState.CreateStateObject(class'NCE_XComGameState_RandomizedUnit'));
		UpdatedUnit.AddComponentObject(RandomizedStatsState);
		GameState.AddStateObject(RandomizedStatsState);
	}

	RandomizedStatsState.ApplyRandomInitialStats(UpdatedUnit);
}

function EventListenerReturn CleanUpComponentStateOnDismiss(Object EventData, Object EventSource, XComGameState GameState, Name EventID, Object CallbackData)
{
	local XComGameState_Unit UnitState, UpdatedUnit;
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local NCE_XComGameState_RandomizedUnit RandomizedState, UpdatedRandomized;

	UnitState = XComGameState_Unit(EventData);
	if(UnitState == none)
		return ELR_NoInterrupt;

	RandomizedState = GetRandomizedStatsComponent(UnitState, GameState);
	if(RandomizedState != none)
	{
		History = `XCOMHISTORY;
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("RandomizedStats State cleanup");
		UpdatedUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', UnitState.ObjectID));
		UpdatedRandomized = NCE_XComGameState_RandomizedUnit(NewGameState.CreateStateObject(class'NCE_XComGameState_RandomizedUnit', RandomizedState.ObjectID));
		NewGameState.RemoveStateObject(UpdatedRandomized.ObjectID);
		UpdatedUnit.RemoveComponentObject(UpdatedRandomized);
		NewGameState.AddStateObject(UpdatedRandomized);
		NewGameState.AddStateObject(UpdatedUnit);
		if (NewGameState.GetNumGameStateObjects() > 0)
			`GAMERULES.SubmitGameState(NewGameState);
		else
			History.CleanupPendingGameState(NewGameState);
	}
	return ELR_NoInterrupt;
}

function NCE_XComGameState_RandomizedUnit GetRandomizedStatsComponent(XComGameState_Unit Unit, optional XComGameState NewGameState)
{
	local NCE_XComGameState_RandomizedUnit RandomizedStats;

	if (Unit != none)
	{
		if(NewGameState != none)
		{
			foreach NewGameState.IterateByClassType(class'NCE_XComGameState_RandomizedUnit', RandomizedStats)
			{
				if(RandomizedStats.OwningObjectID == Unit.ObjectID)
					return RandomizedStats;
			}
		}
		return NCE_XComGameState_RandomizedUnit(Unit.FindComponentObject(class'NCE_XComGameState_RandomizedUnit'));
	}
	return none;
}