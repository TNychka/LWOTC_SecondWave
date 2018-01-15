//---------------------------------------------------------------------------------------
//  FILE:    NCE_XComGameState_RandomizedUnit.uc
//  AUTHOR:  Amineri / Long War Studios
//  PURPOSE: This is a component for the unit game state that stores and computes randomized stat information
//			All randomization use a triangle distribution (same as sum of two dice)
//---------------------------------------------------------------------------------------
class NCE_XComGameState_RandomizedUnit extends XComGameState_BaseObject 
	dependson(X2TacticalGameRulesetDataStructures)
	config(LWOTC_SecondWave_NCE);

struct StatSwap
{
	var ECharStatType StatUp;
	var float StatUp_Amount;
	var ECharStatType StatDown;
	var float StatDown_Amount;
	var float Weight;
	var bool DoesNotApplyToFirstMissionSoldiers;
};

struct StatCaps
{
	var ECharStatType Stat;
	var float Min;
	var float Max;
};

var config array<int> NUM_STAT_SWAPS;  // defines dice that are rolled to determine number of stat swaps applied
var config array<StatSwap> STAT_SWAPS;
var config array<Statcaps> STAT_CAPS;

var bool IsFirstMissionSoldier;
var bool InitialStatsApplied;
var float CharacterInitialStats_Deltas[ECharStatType.EnumCount];

//apply the randomized initial stat offsets, generating them if they don't already exist
function ApplyRandomInitialStats(XComGameState_Unit Unit)
{
	local int idx;
	local float OldValue, NewValue;

	if (!InitialStatsApplied)
	{
		RandomizeInitialStats(Unit);

		for(idx=0; idx < ArrayCount(CharacterInitialStats_Deltas) ; idx++)
		{
			if (ECharStatType(idx) == eStat_Will && Unit.bIsShaken)
				OldValue = Unit.SavedWillValue;
			else
				OldValue = Unit.GetBaseStat(ECharStatType(idx));

			NewValue = OldValue;
			if(CharacterInitialStats_Deltas[idx] != 0)
			{
				NewValue += CharacterInitialStats_Deltas[idx];

				if (ECharStatType(idx) == eStat_Will && Unit.bIsShaken) 
				{
					Unit.SavedWillValue = NewValue;
				}
				else
				{
					if(ECharStatType(idx) == eStat_HP && `TACTICALRULES.TacticalGameIsInPlay()) // need to adjust lowest/highest HP if in tactical
					{
						Unit.LowestHP += CharacterInitialStats_Deltas[idx];
						Unit.HighestHP += CharacterInitialStats_Deltas[idx];
					}
					Unit.SetBaseMaxStat(ECharStatType(idx), NewValue);
				}
			}
		}
		InitialStatsApplied = true;
	}
}

//fill out the class variable array with initial stat deltas
function RandomizeInitialStats(XComGameState_Unit Unit)
{
	local int idx, NumSwaps, iterations;
	local float TotalWeight;
	local StatSwap Swap;
	local XComGameState_BattleData BattleData;
	local bool bIsFirstMission;

	BattleData = XComGameState_BattleData( `XCOMHISTORY.GetSingleGameStateObjectForClass( class'XComGameState_BattleData', true ));
	if(BattleData != none)
		bIsFirstMission = BattleData.m_bIsFirstMission;

	if(bIsFirstMission)
		IsFirstMissionSoldier = Unit.IsInPlay();

	//clear the existing array
	for(idx=0; idx < ArrayCount(CharacterInitialStats_Deltas) ; idx++)
	{
		CharacterInitialStats_Deltas[idx] = 0;
	}

	//set up
	NumSwaps = RollNumStatSwaps();

	TotalWeight = 0.0f;
	foreach default.STAT_SWAPS(Swap)
	{
		TotalWeight += Swap.Weight;
	}

	//randomly apply a bunch of stat swaps to get starting stat offset
	for(idx = 0; idx < NumSwaps; idx++)
	{
		do {
			Swap = SelectRandomStatSwap(TotalWeight);
		} until (IsValidSwap(Swap) || (++iterations > 1000));

		CharacterInitialStats_Deltas[Swap.StatUp] += Swap.StatUp_Amount;
		CharacterInitialStats_Deltas[Swap.StatDown] -= Swap.StatDown_Amount;
	}
}

function int RollNumStatSwaps()
{
	local int Total, StatRoll;

	foreach default.NUM_STAT_SWAPS(StatRoll)
	{
		Total += 1 + `SYNC_RAND(StatRoll);
	}
	return Total;
}

function StatSwap SelectRandomStatSwap(float TotalWeight)
{
	local float finder, selection;
	local StatSwap Swap, ReturnSwap;

	if(default.STAT_SWAPS.Length == 0)
		return Swap;

	finder = 0.0f;
	selection = `SYNC_FRAND * TotalWeight;
	foreach default.STAT_SWAPS(Swap)
	{
		finder += Swap.Weight;
		if(finder > selection)
		{
			break;
		}
	}
	//Swap = default.STAT_SWAPS[default.STAT_SWAPS.Length-1];
	if(`SYNC_RAND(2) == 1)
	{
		ReturnSwap.StatUp = Swap.StatDown;
		ReturnSwap.StatUp_Amount = Swap.StatDown_Amount;
		ReturnSwap.StatDown = Swap.StatUp;
		ReturnSwap.StatDown_Amount = Swap.StatUp_Amount;
		ReturnSwap.DoesNotApplyToFirstMissionSoldiers = Swap.DoesNotApplyToFirstMissionSoldiers;
		return ReturnSwap;
	}
	return Swap;
}

//tests to see whether the given stat swap will exceed any of the configured limits
function bool IsValidSwap(StatSwap Swap)
{
	local StatCaps Cap;

	if(Swap.DoesNotApplyToFirstMissionSoldiers && IsFirstMissionSoldier)
		return false;

	foreach default.STAT_CAPS(Cap)
	{
		if((Cap.Stat == Swap.StatUp)  && (CharacterInitialStats_Deltas[Swap.StatUp] + Swap.StatUp_Amount > Cap.Max))
			return false;
		if((Cap.Stat == Swap.StatDown) && (CharacterInitialStats_Deltas[Swap.StatDown] - Swap.StatDown_Amount < Cap.Min))
			return false;
	}
	return true;
}