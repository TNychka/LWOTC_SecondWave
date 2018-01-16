class ACrit_XComGameState_Manager extends XComGameState_Manager_LWOTC;

`include(LWOTC_SecondWave/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var float Modifier;

`MCM_CH_VersionChecker(class'ModMenu_Options_Defaults'.default.VERSION,class'ModMenu_Options_Listener'.default.CONFIG_VERSION)

static function ACrit_XComGameState_Manager GetAbsolutelyCriticalManager()
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(CampaignSettingsStateObject != none)
		return ACrit_XComGameState_Manager(CampaignSettingsStateObject.FindComponentObject(class'ACrit_XComGameState_Manager'));
	return none;
}

event OnCreation(optional X2DataTemplate InitTemplate)
{
	Modifier = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.ACrit_Modifier,class'ModMenu_Options_Listener'.default.ACrit_Modifier);
}

function UpdateUnitsCritChance()
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local array<X2CharacterTemplate> CharacterTemplates;
	local X2CharacterTemplate Template;
	local X2DownloadableContentInfo_LWOTC_SecondWave ModInfo;
	local XComGameState_CampaignSettings Settings;
	local int DifficultyIndex, OriginalDifficulty, OriginalLowestDifficulty;
	local int CharIdx;
	
	ModInfo = class'X2DownloadableContentInfo_LWOTC_SecondWave'.static.GetDLCInfo();
	if (ModInfo == none)
	{
		`REDSCREEN("LWOTC Second Wave : Unable to find X2DLCInfo");
		return;
	}

	`LOG("ToolboxOptions: Updating Weapon Templates for Randomized Damage");

	Settings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	OriginalDifficulty = Settings.DifficultySetting;
	OriginalLowestDifficulty = Settings.LowestDifficultySetting;

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	if (CharTemplateMgr == none) {
		`Redscreen("LWOTC Second Wave : failed to retrieve CharacterTemplateManager to modify Flank Crit");
		return;
	}

	for( DifficultyIndex = `MIN_DIFFICULTY_INDEX; DifficultyIndex <= `MAX_DIFFICULTY_INDEX; ++DifficultyIndex )
	{
		Settings.SetDifficulty(DifficultyIndex, -1, -1, -1, false, true);

		CharacterTemplates = GetAllCharacterTemplates(CharTemplateMgr);
	
		foreach CharacterTemplates(Template)
		{
			CharIdx = ModInfo.arrDefaultFlankingCrit.Find('CharacterTemplateName', name(Template.DataName $ DifficultyIndex));
			if (CharIdx == -1)
			{
				`Redscreen("LWOTC Second Wave : error refreshing character config for flanking crit " $ Template.DataName $ DifficultyIndex);
			}
			else
			{
				Template.CharacterBaseStats[eStat_FlankingCritChance] = ModInfo.arrDefaultFlankingCrit[CharIdx].CritValue;
			}

			if(`SecondWaveEnabled('AbsolutelyCritical'))
			{
				Template.CharacterBaseStats[eStat_FlankingCritChance] = Template.CharacterBaseStats[eStat_FlankingCritChance] * Modifier;
			}
		}
	}

	//restore difficulty settings
	Settings.SetDifficulty(OriginalLowestDifficulty, -1, -1, -1, false, true);
	Settings.SetDifficulty(OriginalDifficulty, -1, -1, -1, false, false);		
}

static function array<X2CharacterTemplate> GetAllCharacterTemplates(X2CharacterTemplateManager CharTemplateMgr)
{
	local array<X2CharacterTemplate> CharacterTemplates;
	local X2DataTemplate Template;
	local X2CharacterTemplate CharacterTemplate;

	foreach CharTemplateMgr.IterateTemplates(Template, none)
	{
		CharacterTemplate = X2CharacterTemplate(Template);
		if(CharacterTemplate != none)
		{
			CharacterTemplates.AddItem(CharacterTemplate);
		}
	}

	return CharacterTemplates;
}
