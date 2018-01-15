//---------------------------------------------------------------------------------------
//  FILE:    X2StrategyElement_RandomizedSoldierRewards.uc
//  AUTHOR:  Amineri / Long War Studios
//  PURPOSE: Methods for handling creation and rankups of randomized reward soldiers
//---------------------------------------------------------------------------------------
class NCE_X2StrategyElement_RandomizedSoldierRewards extends X2StrategyElement
	dependson(X2RewardTemplate);

static function GenerateCapturedSoldierReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	local XComGameStateHistory History;
	local XComGameState_HeadquartersAlien AlienHQ;
	local int CapturedSoldierIndex;

	History = `XCOMHISTORY;

	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));

	// first check if the aliens have captured one of our soldiers. If so, then they get to be the reward
	if(AlienHQ.CapturedSoldiers.Length > 0)
	{
		// pick a soldier to rescue and save them as the reward state
		CapturedSoldierIndex = class'Engine'.static.GetEngine().SyncRand(AlienHQ.CapturedSoldiers.Length, "GenerateSoldierReward");
		RewardState.RewardObjectReference = AlienHQ.CapturedSoldiers[CapturedSoldierIndex];

		// remove the soldier from the captured unit list so they don't show up again later in the playthrough
		AlienHQ = XComGameState_HeadquartersAlien(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersAlien', AlienHQ.ObjectID));
		AlienHQ.CapturedSoldiers.Remove(CapturedSoldierIndex, 1);
	}
	else
	{
		// somehow the soldier to be rescued has been pulled out from under us! Generate one as a fallback.
		GeneratePersonnelReward(RewardState, NewGameState, RewardScalar, RegionRef);
	}
}


static function GeneratePersonnelReward(XComGameState_Reward RewardState, XComGameState NewGameState, optional float RewardScalar = 1.0, optional StateObjectReference RegionRef)
{
	local XComGameState_Unit NewUnitState;
	local XComGameState_WorldRegion RegionState;
	local name nmCountry;
	
	// Grab the region and pick a random country
	nmCountry = '';
	RegionState = XComGameState_WorldRegion(`XCOMHISTORY.GetGameStateForObjectID(RegionRef.ObjectID));

	if(RegionState != none)
	{
		nmCountry = RegionState.GetMyTemplate().GetRandomCountryInRegion();
	}

	NewUnitState = CreatePersonnelUnit(NewGameState, RewardState.GetMyTemplate().rewardObjectTemplateName, nmCountry, (RewardState.GetMyTemplateName() == 'Reward_Rookie'));
	RewardState.RewardObjectReference = NewUnitState.GetReference();
}

static function XComGameState_Unit CreatePersonnelUnit(XComGameState NewGameState, name nmCharacter, name nmCountry, optional bool bIsRookie)
{
	local XComGameStateHistory History;
	local XComGameState_Unit NewUnitState;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComGameState_HeadquartersResistance ResistanceHQ;
	local int idx, NewRank, StartingIdx;

	History = `XCOMHISTORY;

	//Use the character pool's creation method to retrieve a unit
	NewUnitState = `CHARACTERPOOLMGR.CreateCharacter(NewGameState, `XPROFILESETTINGS.Data.m_eCharPoolUsage, nmCharacter, nmCountry);
	
	// New Event Trigger
	`XEVENTMGR.TriggerEvent( 'SoldierCreatedEvent', NewUnitState, NewUnitState, NewGameState );
	// END CHANGES

	NewUnitState.RandomizeStats();

	if (NewUnitState.IsSoldier())
	{
		XComHQ = XComGameState_HeadquartersXCom(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		ResistanceHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));

		if (!NewGameState.GetContext().IsStartState())
		{
			ResistanceHQ = XComGameState_HeadquartersResistance(NewGameState.ModifyStateObject(class'XComGameState_HeadquartersResistance', ResistanceHQ.ObjectID));
		}

		NewUnitState.ApplyInventoryLoadout(NewGameState);
		NewRank = class'X2StrategyElement_DefaultRewards'.static.GetPersonnelRewardRank(true, bIsRookie);
		NewUnitState.SetXPForRank(NewRank);
		NewUnitState.StartingRank = NewRank;
		StartingIdx = 0;

		if(NewUnitState.GetMyTemplate().DefaultSoldierClass != '' && NewUnitState.GetMyTemplate().DefaultSoldierClass != class'X2SoldierClassTemplateManager'.default.DefaultSoldierClass)
		{
			// Some character classes start at squaddie on creation
			StartingIdx = 1;
		}

		for (idx = StartingIdx; idx < NewRank; idx++)
		{
			// Rank up to squaddie
			if (idx == 0)
			{
				NewUnitState.RankUpSoldier(NewGameState, ResistanceHQ.SelectNextSoldierClass());
				NewUnitState.ApplySquaddieLoadout(NewGameState);
				NewUnitState.bNeedsNewClassPopup = false;
			}
			else
			{
				NewUnitState.RankUpSoldier(NewGameState, NewUnitState.GetSoldierClassTemplate().DataName);
			}
			// New Event Trigger
			`XEVENTMGR.TriggerEvent( 'RankUpEvent', NewUnitState, NewUnitState, NewGameState );
			// END CHANGES
		}

		// Set an appropriate fame score for the unit
		NewUnitState.StartingFame = XComHQ.AverageSoldierFame;
		NewUnitState.bIsFamous = true;
	}
	else
	{
		NewUnitState.SetSkillLevel(class'X2StrategyElement_DefaultRewards'.static.GetPersonnelRewardRank(false));
	}

	return NewUnitState;
}