
class XComGameState_AIReinforcementSpawner_LWOTC extends XComGameState_AIReinforcementSpawner;

function EventListenerReturn OnReinforcementSpawnerCreated(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComGameState NewGameState;
	local XComGameState_AIReinforcementSpawner NewSpawnerState;
	local X2EventManager EventManager;
	local Object ThisObj;
	local X2CharacterTemplate SelectedTemplate;
	local XComGameState_Player PlayerState;
	local XComGameState_BattleData BattleData;
	local XComGameState_MissionSite MissionSiteState;
	local XComAISpawnManager SpawnManager;
	local int AlertLevel, ForceLevel;
	local XComGameStateHistory History;
	local Name CharTemplateName;
	local X2CharacterTemplateManager CharTemplateManager;

	CharTemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

	SpawnManager = `SPAWNMGR;
	History = `XCOMHISTORY;

	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	ForceLevel = BattleData.GetForceLevel();
	AlertLevel = BattleData.GetAlertLevel();

	if( BattleData.m_iMissionID > 0 )
	{
		MissionSiteState = XComGameState_MissionSite(History.GetGameStateForObjectID(BattleData.m_iMissionID));

		if( MissionSiteState != None && MissionSiteState.SelectedMissionData.SelectedMissionScheduleName != '' )
		{
			AlertLevel = MissionSiteState.SelectedMissionData.AlertLevel;
			ForceLevel = MissionSiteState.SelectedMissionData.ForceLevel;
		}
	}

	// Select the spawning visualization mechanism and build the persistent in-world visualization for this spawner
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState(string(GetFuncName()));

	NewSpawnerState = XComGameState_AIReinforcementSpawner(NewGameState.ModifyStateObject(class'XComGameState_AIReinforcementSpawner', ObjectID));

	// choose reinforcement spawn location

	// build a character selection that will work at this location
	SpawnManager.SelectPodAtLocation(NewSpawnerState.SpawnInfo, ForceLevel, AlertLevel, BattleData.ActiveSitReps);

	if( NewSpawnerState.SpawnVisualizationType == 'ChosenSpecialNoReveal' ||
	   NewSpawnerState.SpawnVisualizationType == 'ChosenSpecialTopDownReveal' )
	{
		NewSpawnerState.SpawnInfo.bDisableScamper = true;
	}

	// explicitly disabled all timed loot from reinforcement groups
	NewSpawnerState.SpawnInfo.bGroupDoesNotAwardLoot = true;

	// fallback to 'PsiGate' visualization if the requested visualization is using 'ATT' but that cannot be supported
	if( NewSpawnerState.SpawnVisualizationType == 'ATT' )
	{
		// determine if the spawning mechanism will be via ATT or PsiGate
		//  A) ATT requires open sky above the reinforcement location
		//  B) ATT requires that none of the selected units are oversized (and thus don't make sense to be spawning from ATT)
		if( DoesLocationSupportATT(NewSpawnerState.SpawnInfo.SpawnLocation) )
		{
			// determine if we are going to be using psi gates or the ATT based on if the selected templates support it
			foreach NewSpawnerState.SpawnInfo.SelectedCharacterTemplateNames(CharTemplateName)
			{
				SelectedTemplate = CharTemplateManager.FindCharacterTemplate(CharTemplateName);

				if( !SelectedTemplate.bAllowSpawnFromATT )
				{
					NewSpawnerState.SpawnVisualizationType = 'PsiGate';
					break;
				}
			}
		}
		else
		{
			NewSpawnerState.SpawnVisualizationType = 'PsiGate';
		}
	}

	if( NewSpawnerState.SpawnVisualizationType != '' && 
	   NewSpawnerState.SpawnVisualizationType != 'TheLostSwarm' && 
	   NewSpawnerState.SpawnVisualizationType != 'ChosenSpecialNoReveal' &&
	   NewSpawnerState.SpawnVisualizationType != 'ChosenSpecialTopDownReveal'  &&
	   `SecondWaveEnabled('SignalReserves'))
	{
		XComGameStateContext_ChangeContainer(NewGameState.GetContext()).BuildVisualizationFn = NewSpawnerState.BuildVisualizationForSpawnerCreation;
		NewGameState.GetContext().SetAssociatedPlayTiming(SPT_AfterSequential);
	}

	`TACTICALRULES.SubmitGameState(NewGameState);

	// no countdown specified, spawn reinforcements immediately
	if( Countdown <= 0 )
	{
		NewSpawnerState.SpawnReinforcements();
	}
	// countdown is active, need to listen for AI Turn Begun in order to tick down the countdown
	else
	{
		EventManager = `XEVENTMGR;
		ThisObj = self;

		PlayerState = class'XComGameState_Player'.static.GetPlayerState(NewSpawnerState.SpawnInfo.Team);
		EventManager.RegisterForEvent(ThisObj, 'PlayerTurnBegun', OnTurnBegun, ELD_OnStateSubmitted, , PlayerState);
	}

	return ELR_NoInterrupt;
}

// TODO: update this function to better consider the space that an ATT requires
private function bool DoesLocationSupportATT(Vector TargetLocation)
{
	local TTile TargetLocationTile;
	local TTile AirCheckTile;
	local VoxelRaytraceCheckResult CheckResult;
	local XComWorldData WorldData;

	WorldData = `XWORLD;

		TargetLocationTile = WorldData.GetTileCoordinatesFromPosition(TargetLocation);
	AirCheckTile = TargetLocationTile;
	AirCheckTile.Z = WorldData.NumZ - 1;

	// the space is free if the raytrace hits nothing
	return (WorldData.VoxelRaytrace_Tiles(TargetLocationTile, AirCheckTile, CheckResult) == false);
}

