class UIScreenListener_All extends UIScreenListener dependson(X2DownloadableContentInfo_LWOTC_SecondWave);

var bool CapturedDefaultBaseDamage;
var bool CapturedDefaultFlankedCrit;

defaultproperties
{
	// Leave this none so it can be triggered anywhere, gate inside the OnInit
	ScreenClass = none;
}

event OnInit(UIScreen Screen)
{
	if(UIShell(Screen) != none && !CapturedDefaultBaseDamage)  // this captures UIShell and UIFinalShell
	{
		// capture default spread settings for all weapons
		StoreDefaultWeaponBaseDamageValues();
		CapturedDefaultBaseDamage = true;
	}

	if(UIShell(Screen) != none && !CapturedDefaultFlankedCrit)  // this captures UIShell and UIFinalShell
	{
		StoreDefaultFlankingCritValues();
		CapturedDefaultFlankedCrit = true;
	}
}

function StoreDefaultWeaponBaseDamageValues()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2WeaponTemplate Template;
	local array<X2WeaponTemplate> AllWeaponTemplates;
	local DefaultBaseDamageEntry BaseDamageEntry;
	local X2DownloadableContentInfo_LWOTC_SecondWave ModInfo;

	ModInfo = class'X2DownloadableContentInfo_LWOTC_SecondWave'.static.GetDLCInfo();
	if (ModInfo == none)
	{
		`REDSCREEN("LWOTC Second Wave : Unable to find X2DLCInfo");
		return;
	}

	//get access to item element template manager
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (ItemTemplateManager == none) {
		`Redscreen("LWOTC Second Wave : failed to retrieve ItemTemplateManager to capture Spread");
		return;
	}

	ModInfo.arrDefaultBaseDamage.Length = 0;

	AllWeaponTemplates = ItemTemplateManager.GetAllWeaponTemplates();
	
	foreach AllWeaponTemplates(Template)
	{
		BaseDamageEntry.WeaponTemplateName = Template.DataName;
		BaseDamageEntry.BaseDamage = Template.BaseDamage;
		ModInfo.arrDefaultBaseDamage.AddItem(BaseDamageEntry);
	}
}

function StoreDefaultFlankingCritValues()
{
	local X2CharacterTemplateManager CharTemplateMgr;
	local array<X2CharacterTemplate> CharacterTemplates;
	local X2CharacterTemplate Template;
	local X2DownloadableContentInfo_LWOTC_SecondWave ModInfo;
	local XComGameState_CampaignSettings Settings;
	local int DifficultyIndex, OriginalDifficulty, OriginalLowestDifficulty;
	local DefaultFlankingCritEntry Entry;

	ModInfo = class'X2DownloadableContentInfo_LWOTC_SecondWave'.static.GetDLCInfo();
	if (ModInfo == none)
	{
		`REDSCREEN("LWOTC Second Wave : Unable to find X2DLCInfo");
		return;
	}

	CharTemplateMgr = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();
	if (CharTemplateMgr == none) {
		`Redscreen("LWOTC Second Wave : failed to retrieve CharacterTemplateManager to modify Flank Crit");
		return;
	}

	ModInfo.arrDefaultFlankingCrit.Length = 0;

	Settings = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));

	OriginalDifficulty = Settings.DifficultySetting;
	OriginalLowestDifficulty = Settings.LowestDifficultySetting;

	for( DifficultyIndex = `MIN_DIFFICULTY_INDEX; DifficultyIndex <= `MAX_DIFFICULTY_INDEX; ++DifficultyIndex )
	{
		Settings.SetDifficulty(DifficultyIndex, -1, -1, -1, false, true);

		CharacterTemplates = class'ACrit_XComGameState_Manager'.static.GetAllCharacterTemplates(CharTemplateMgr);

		foreach CharacterTemplates(Template)
		{
			Entry.CharacterTemplateName = name(Template.DataName $ DifficultyIndex);
			Entry.CritValue = Template.CharacterBaseStats[eStat_FlankingCritChance];
			ModInfo.arrDefaultFlankingCrit.AddItem(Entry);
		}
	}

	//restore difficulty settings
	Settings.SetDifficulty(OriginalLowestDifficulty, -1, -1, -1, false, true);
	Settings.SetDifficulty(OriginalDifficulty, -1, -1, -1, false, false);	
}