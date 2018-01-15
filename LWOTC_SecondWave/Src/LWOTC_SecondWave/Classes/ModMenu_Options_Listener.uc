class ModMenu_Options_Listener extends UIScreenListener config(LWOTC_SecondWave);

`include(LWOTC_SecondWave/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(LWOTC_SecondWave/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var localized string Settings_Category;
var localized string Page_Title;

var localized string RedFog_Title;
var localized string RedFog_EnabledAliens_Setting;
var localized string RedFog_EnabledAliens_Tooltip;
var localized string RedFog_EnabledXcom_Setting;
var localized string RedFog_EnabledXcom_Tooltip;
var localized string RedFog_IsLinear_Setting;
var localized string RedFog_IsLinear_Tooltip;
var localized string RedFog_PenaltyType_Setting;
var localized string RedFog_PenaltyType_Tooltip;
var localized string RedFog_HealingType_Setting;
var localized string RedFog_HealingType_Tooltip;

var localized string HiddenP_Title;
var localized string HiddenP_PercentGuaranteedStat_Setting;
var localized string HiddenP_PercentGuaranteedStat_Tooltip;

var localized string WeaponR_Title;
var localized string WeaponR_DamageRange_Setting;
var localized string WeaponR_DamageRange_Tooltip;

// Red Fog
var config bool RedFog_EnabledAlien;
var config bool RedFog_EnabledXcom;
var config bool RedFog_IsLinear;
var config string RedFog_PenaltyType;
var config string RedFog_HealingType;

// Hidden Potential
var config float HiddenP_PercentGuaranteedStat;

// Weapon Roulette
var config float WeaponR_DamageRange;

var config int CONFIG_VERSION;

defaultproperties
{
    ScreenClass = none;
}

`MCM_CH_VersionChecker(class'ModMenu_Options_Defaults'.default.VERSION,CONFIG_VERSION)

event OnInit(UIScreen Screen)
{
	// Everything out here runs on every UIScreen. Not great but necessary.
	if (MCM_API(Screen) != none)
	{
		// Everything in here runs only when you need to touch MCM.
		`MCM_API_Register(Screen, ClientModCallback);
	}
}

simulated function ClientModCallback(MCM_API_Instance ConfigAPI, int GameMode)
{
    local MCM_API_SettingsPage Page;
    local MCM_API_SettingsGroup RedFogGroup, HiddenPGroup, WeaponRGroup;
	local array<string> penaltyOptions, healingOptions;
    
    LoadSavedSettings();

	if (GameMode == eGameMode_MainMenu)
	{
		Page = ConfigAPI.NewSettingsPage(Settings_Category);
		Page.SetPageTitle(Page_Title);
		Page.SetSaveHandler(SaveButtonClicked);
    
		// Red Fog Settings
		RedFogGroup = Page.AddGroup('redfog', RedFog_Title);
    
		RedFogGroup.AddCheckbox('checkboxEnabledAliens', RedFog_EnabledAliens_Setting, RedFog_EnabledAliens_Tooltip, RedFog_EnabledAlien, CheckboxSaveHandlerEnabledAliens);
		RedFogGroup.AddCheckbox('checkboxEnabledXcom', RedFog_EnabledXcom_Setting, RedFog_EnabledXcom_Tooltip, RedFog_EnabledXcom, CheckboxSaveHandlerEnabledXcom);
		RedFogGroup.AddCheckbox('checkboxLinear', RedFog_IsLinear_Setting, RedFog_IsLinear_Tooltip, RedFog_IsLinear, CheckboxSaveHandlerLinear);

		penaltyOptions.Length = 0;
		penaltyOptions.AddItem("Additive");
		penaltyOptions.AddItem("Multiplicative");
		RedFogGroup.AddSpinner('spinnerPenalty', RedFog_PenaltyType_Setting, RedFog_PenaltyType_Tooltip, penaltyOptions, RedFog_PenaltyType, SpinnerSaveLoggerPenalty);

		healingOptions.Length = 0;
		healingOptions.AddItem("Current HP");
		healingOptions.AddItem("Average HP");
		healingOptions.AddItem("Lowest HP");
		RedFogGroup.AddSpinner('spinnerHealing', RedFog_HealingType_Setting, RedFog_HealingType_Tooltip, healingOptions, RedFog_HealingType, SpinnerSaveLoggerHealing);

		// Hidden Potential Settings
		HiddenPGroup = Page.AddGroup('hiddenp', HiddenP_Title);
		HiddenPGroup.AddSlider('SliderPercentGuaranteedStat', HiddenP_PercentGuaranteedStat_Setting, HiddenP_PercentGuaranteedStat_Tooltip, 0, 1, 0, HiddenP_PercentGuaranteedStat, SliderSaveLoggerPercentGuaranteedStat);

		// Weapon Roulette Settings
		WeaponRGroup = Page.AddGroup('weaponr', WeaponR_Title);
		WeaponRGroup.AddSlider('SliderDamageRange', WeaponR_DamageRange_Setting, WeaponR_DamageRange_Tooltip, 0, 100, 5, WeaponR_DamageRange, SliderSaveLoggerDamageRange);

		Page.ShowSettings();
	}
}

`MCM_API_BasicCheckboxSaveHandler(CheckboxSaveHandlerEnabledAliens, RedFog_EnabledAlien)
`MCM_API_BasicCheckboxSaveHandler(CheckboxSaveHandlerEnabledXcom, RedFog_EnabledXcom)
`MCM_API_BasicCheckboxSaveHandler(CheckboxSaveHandlerLinear, RedFog_IsLinear)
`MCM_API_BasicSpinnerSaveHandler(SpinnerSaveLoggerPenalty, RedFog_PenaltyType)
`MCM_API_BasicSpinnerSaveHandler(SpinnerSaveLoggerHealing, RedFog_HealingType)
`MCM_API_BasicSliderSaveHandler(SliderSaveLoggerPercentGuaranteedStat, HiddenP_PercentGuaranteedStat)
`MCM_API_BasicSliderSaveHandler(SliderSaveLoggerDamageRange, WeaponR_DamageRange)

simulated function LoadSavedSettings()
{
    RedFog_EnabledAlien = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.RedFog_EnabledAlien,RedFog_EnabledAlien);
	RedFog_EnabledXcom = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.RedFog_EnabledXcom,RedFog_EnabledXcom);
	RedFog_IsLinear = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.RedFog_IsLinear,RedFog_IsLinear);
	RedFog_PenaltyType = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.RedFog_PenaltyType,RedFog_PenaltyType);
	RedFog_HealingType = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.RedFog_HealingType,RedFog_HealingType);
	HiddenP_PercentGuaranteedStat = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.HiddenP_PercentGuaranteedStat,HiddenP_PercentGuaranteedStat);
	WeaponR_DamageRange = `MCM_CH_GetValue(class'ModMenu_Options_Defaults'.default.WeaponR_DamageRange,WeaponR_DamageRange);
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
    self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
    self.SaveConfig();
}