class WeaponR_XComGameState_Manager extends XComGameState_Manager_LWOTC;

`include(LWOTC_SecondWave/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var float DamageRange;

`MCM_CH_VersionChecker(class'ModMenu_Options_Defaults'.default.VERSION,class'ModMenu_Options_Listener'.default.CONFIG_VERSION)

static function WeaponR_XComGameState_Manager GetWeaponRouletteManager()
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;

	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	if(CampaignSettingsStateObject != none)
		return WeaponR_XComGameState_Manager(CampaignSettingsStateObject.FindComponentObject(class'WeaponR_XComGameState_Manager'));
	return none;
}

event OnCreation(optional X2DataTemplate InitTemplate)
{
	DamageRange = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.WeaponR_DamageRange,class'ModMenu_Options_Listener'.default.WeaponR_DamageRange);
}

function UpdateWeaponTemplates_RandomizedDamage()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local int DifficultyIndex, OriginalDifficulty, OriginalLowestDifficulty;
	local XComGameState_CampaignSettings Settings;
	local XComGameStateHistory History;
	local X2WeaponTemplate Template;
	local array<X2WeaponTemplate> WeaponTemplates;
	local int WeaponIdx;
	local X2DownloadableContentInfo_LWOTC_SecondWave ModInfo;

	ModInfo = class'X2DownloadableContentInfo_LWOTC_SecondWave'.static.GetDLCInfo();
	if (ModInfo == none)
	{
		`REDSCREEN("LWOTC Second Wave : Unable to find X2DLCInfo");
		return;
	}

	`LOG("ToolboxOptions: Updating Weapon Templates for Randomized Damage");

	History = `XCOMHISTORY;
	// The CampaignSettings are initialized in CreateStrategyGameStart, so we can pull it from the history here
	Settings = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	OriginalDifficulty = Settings.DifficultySetting;
	OriginalLowestDifficulty = Settings.LowestDifficultySetting;

	//get access to item element template manager
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (ItemTemplateManager == none) {
		`Redscreen("LW Toolbox : failed to retrieve ItemTemplateManager to modify Spread");
		return;
	}

	for( DifficultyIndex = `MIN_DIFFICULTY_INDEX; DifficultyIndex <= `MAX_DIFFICULTY_INDEX; ++DifficultyIndex )
	{
		Settings.SetDifficulty(DifficultyIndex, -1, -1, -1, false, true);

		WeaponTemplates = ItemTemplateManager.GetAllWeaponTemplates();
	
		foreach WeaponTemplates(Template)
		{
			if(`SecondWaveEnabled('DamageRoulette'))
			{
				Template.BaseDamage.Spread = Min(Template.BaseDamage.Damage - 1, (Template.BaseDamage.Damage * DamageRange + 50) / 100);
			}
			else
			{
				WeaponIdx = ModInfo.arrDefaultBaseDamage.Find('WeaponTemplateName', Template.DataName);
				if (WeaponIdx == -1)
					Template.BaseDamage.Spread = Template.default.BaseDamage.Spread;
				else
					Template.BaseDamage.Spread = ModInfo.arrDefaultBaseDamage[WeaponIdx].BaseDamage.Spread;
			}
		}

	}

	//restore difficulty settings
	Settings.SetDifficulty(OriginalLowestDifficulty, -1, -1, -1, false, true);
	Settings.SetDifficulty(OriginalDifficulty, -1, -1, -1, false, false);		
}