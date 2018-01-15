class HiddenP_XComGameState_Manager extends XComGameState_Manager_LWOTC config(LWOTC_SecondWave_HiddenPotential);

`include(LWOTC_SecondWave/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var float PercentGuaranteedStat;

var config array<ECharStatType> RANDOMIZED_LEVELUP_STATS;

`MCM_CH_VersionChecker(class'ModMenu_Options_Defaults'.default.VERSION,class'ModMenu_Options_Listener'.default.CONFIG_VERSION)

static function HiddenP_XComGameState_Manager GetHiddenPotentialManager()
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(CampaignSettingsStateObject != none)
		return HiddenP_XComGameState_Manager(CampaignSettingsStateObject.FindComponentObject(class'HiddenP_XComGameState_Manager'));
	return none;
}

event OnCreation(optional X2DataTemplate InitTemplate)
{
	PercentGuaranteedStat = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.HiddenP_PercentGuaranteedStat,class'ModMenu_Options_Listener'.default.HiddenP_PercentGuaranteedStat);
}

function RegisterManager()
{
	`XCOMHISTORY.RegisterOnNewGameStateDelegate(OnNewGameState_RankWatcher);
}

function OnNewGameState_RankWatcher(XComGameState GameState)
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local int StateObjectIndex;
	local int idx, PreviousRank, CurrentRank;
	local XComGameState_Unit RankChangedUnit, UpdatedUnit, PreviousUnitState;
	local array<XComGameState_Unit> RankChangedObjects;  // is generically just a XComGameState_BaseObject, post the change

	if(!`SecondWaveEnabled('HiddenPotential'))
		return; 

	RankChangedObjects.Length = 0;
	GetRankChangedObjectList(GameState, RankChangedObjects);
	
	if(RankChangedObjects.Length == 0)
		return;

	History = `XCOMHISTORY;
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update RandomizedLevelupStats OnNewGameState_RankWatcher");
	for( StateObjectIndex = 0; StateObjectIndex < RankChangedObjects.Length; ++StateObjectIndex )
	{	
		RankChangedUnit = RankChangedObjects[StateObjectIndex];
		PreviousUnitState = XcomGameState_Unit(History.GetGameStateForObjectID(RankChangedUnit.ObjectID, , GameState.HistoryIndex - 1));
		PreviousRank = PreviousUnitState.GetRank();
		CurrentRank = RankChangedUnit.GetRank() ;

		UpdatedUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', RankChangedUnit.ObjectID));
		NewGameState.AddStateObject(UpdatedUnit);

		//reset randomized stats back to previous value
		for(idx=0; idx < eStat_MAX ; idx++)
		{
			if(default.RANDOMIZED_LEVELUP_STATS.Find(ECharStatType(idx)) != -1)
			{
				if (ECharStatType(idx) == eStat_Will && PreviousUnitState.bIsShaken)
					UpdatedUnit.SavedWillValue = PreviousUnitState.SavedWillValue;
				else
					UpdatedUnit.SetBaseMaxStat(ECharStatType(idx), PreviousUnitState.GetBaseStat(ECharStatType(idx)));
			}
		}

 		for(idx = PreviousRank; idx < CurrentRank; idx++)
		{
			ApplyRankUpRandomizedStats(UpdatedUnit, idx, NewGameState);
		}
	}
	if(NewGameState.GetNumGameStateObjects() > 0)
		`GAMERULES.SubmitGameState(NewGameState);
	else
		History.CleanupPendingGameState(NewGameState);
}

function GetRankChangedObjectList(XComGameState NewGameState, out array<XComGameState_Unit> OutRankChangedObjects)
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

			if(UnitStatePrevious != none && UnitStateCurrent.GetRank() != UnitStatePrevious.GetRank())
			{
				OutRankChangedObjects.AddItem(UnitStateCurrent);
			}
		}
	}
}

function ApplyRankUpRandomizedStats(XComGameState_Unit UnitState, int NewRank, XComGameState GameState)
{
	local int idx;
	local float BaseStat, NewValue, AutoIncrease, RandIncrease, ClampStat;
	local float PctAuto;
	local float Increase1, Increase2;

	if(UnitState == none)
		return;

	PctAuto = PercentGuaranteedStat;

	for(idx=0; idx < eStat_Max ; idx++)
	{
		if(default.RANDOMIZED_LEVELUP_STATS.Find(ECharStatType(idx)) != -1)
		{
			BaseStat = GetTemplateCharacterStat(UnitState, ECharStatType(idx), ClampStat, NewRank);
			if (ECharStatType(idx) == eStat_Will && UnitState.bIsShaken)
				NewValue = UnitState.SavedWillValue;
			else
				NewValue = UnitState.GetBaseStat(ECharStatType(idx));

			if(BaseStat < 1.0f)
			{
				Increase1 = `SYNC_FRAND();
				if(Increase1 < BaseStat)
					Increase2 = 1.0f;
				else
					Increase2 = 0.0f;
				NewValue += Increase2;
			}
			else 
			{
				AutoIncrease = FFloor(PctAuto * BaseStat); 
				RandIncrease = BaseStat - AutoIncrease;
				RandIncrease += 1;
				Increase1 = `SYNC_RAND(int(RandIncrease));
				Increase2 = `SYNC_RAND(int(RandIncrease));
				NewValue += AutoIncrease + Increase1 + Increase2;
				if(RandIncrease - int(RandIncrease) > 0)
					NewValue += 1;
			}

			if(ClampStat > 0)
				NewValue = Min(NewValue, ClampStat);

			if (ECharStatType(idx) == eStat_Will && UnitState.bIsShaken)
				UnitState.SavedWillValue = NewValue;
			else
				UnitState.SetBaseMaxStat(ECharStatType(idx), NewValue);

		}
	}
}

//Rank of -1 refers to the unit's base stats, otherwise the gain from going from Rank to Rank+1
simulated function float GetTemplateCharacterStat(XComGameState_Unit Unit, ECharStatType Stat, out float MaxValue, optional int Rank = -1)
{
	local array<SoldierClassStatType> StatProgressionArray;
	local SoldierClassStatType StatProgression;
	local X2SoldierClassTemplate ClassTemplate;
	local float SumStat;
	local int idx, MaxRank;

	if(Unit == none) return 0.0f;
	if(Rank < 0)
	{
		if(Unit.GetMyTemplate() != none)
			return Unit.GetMyTemplate().CharacterBaseStats[Stat];
	}
	else // level up stat
	{
		ClassTemplate = Unit.GetSoldierClassTemplate();
		if(ClassTemplate != none)
		{
			foreach class'X2SoldierClassTemplateManager'.default.GlobalStatProgression(StatProgression)  //handle global stats (Will, in base-game)
			{
				if(StatProgression.StatType == Stat)
				{
					MaxValue = StatProgression.CapStatAmount;

					if(StatProgression.RandStatAmount <= 0)
						return StatProgression.StatAmount;
					else
						return StatProgression.StatAmount + (StatProgression.RandStatAmount-1.0f)/2.0f; //take average value
				}
			}

			MaxRank = ClassTemplate.GetMaxConfiguredRank();
			if (Rank < 0 || Rank > MaxRank)
				return 0.0f;

			for(idx=0; idx < MaxRank ; idx++)
			{
				StatProgressionArray = ClassTemplate.GetStatProgression(idx);
				foreach StatProgressionArray(StatProgression)
				{
					if(StatProgression.StatType == Stat)
						SumStat += StatProgression.StatAmount;
				}
			}
			if(SumStat < class'X2ExperienceConfig'.static.GetMaxRank())
			{
				return (SumStat / float(class'X2ExperienceConfig'.static.GetMaxRank()));
			}
			StatProgressionArray = ClassTemplate.GetStatProgression(Rank);
			foreach StatProgressionArray(StatProgression)
			{
				if(StatProgression.StatType == Stat)
				{
					MaxValue = StatProgression.CapStatAmount;

					if(StatProgression.RandStatAmount <= 0)
						return StatProgression.StatAmount;
					else
						return StatProgression.StatAmount + (StatProgression.RandStatAmount-1.0f)/2.0f; //take average value
				}
			}
		}
	}
	return 0.0f;
}

// Not sure if this is necessary?
function PatchupMissingPCSStats()
{
	local XComGameStateHistory History;
	local XComGameState NewGameState;
	local XComGameState_Unit Unit, UpdatedUnit;
	local float CurrentPCSStat, IdealPCSStat, MaxPCSStat;

	History = `XCOMHISTORY;

	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Updating Missing PCS Stats");
	foreach History.IterateByClassType(class'XComGameState_Unit', Unit)
	{
		if(Unit.IsSoldier() && Unit.GetRank() > 0)
		{
			CurrentPCSStat = Unit.GetCurrentStat(eStat_CombatSims);
			IdealPCSStat = GetTemplateCharacterStat(Unit, eStat_CombatSims, MaxPCSStat, 1);
			if(CurrentPCSStat < IdealPCSStat)
			{
				UpdatedUnit = XComGameState_Unit(NewGameState.CreateStateObject(class'XComGameState_Unit', Unit.ObjectID));
				NewGameState.AddStateObject(UpdatedUnit);
				UpdatedUnit.SetBaseMaxStat(eStat_CombatSims, IdealPCSStat);
			}
		}
	}
	if (NewGameState.GetNumGameStateObjects() > 0)
		`GAMERULES.SubmitGameState(NewGameState);
	else
		History.CleanupPendingGameState(NewGameState);
}