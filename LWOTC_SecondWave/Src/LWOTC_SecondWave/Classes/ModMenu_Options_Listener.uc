class ModMenu_Options_Listener extends UIScreenListener config(LWOTC_SecondWave);

`include(LWOTC_SecondWave/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(LWOTC_SecondWave/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

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
		Page = ConfigAPI.NewSettingsPage("LWOTC Settings");
		Page.SetPageTitle("LWOTC Settings");
		Page.SetSaveHandler(SaveButtonClicked);
    
		// Red Fog Settings
		RedFogGroup = Page.AddGroup('redfog', "Red Fog Settings");
    
		RedFogGroup.AddCheckbox('checkboxEnabledAliens', "Red Fog enabled for Advent", "Red Fog enabled for Advent", RedFog_EnabledAlien, CheckboxSaveHandlerEnabledAliens);
		RedFogGroup.AddCheckbox('checkboxEnabledXcom', "Red Fog enabled for XCOM", "Red Fog enabled for XCOM", RedFog_EnabledXcom, CheckboxSaveHandlerEnabledXcom);
		RedFogGroup.AddCheckbox('checkboxLinear', "Red Fog is linearly applied", "Alternative being Quadratic", RedFog_IsLinear, CheckboxSaveHandlerLinear);

		penaltyOptions.Length = 0;
		penaltyOptions.AddItem("Additive");
		penaltyOptions.AddItem("Multiplicative");
		RedFogGroup.AddSpinner('spinnerPenalty', "Red Fog Penalty Type", "Red Fog Penalty Type", penaltyOptions, RedFog_PenaltyType, SpinnerSaveLoggerPenalty);

		healingOptions.Length = 0;
		healingOptions.AddItem("Current HP");
		healingOptions.AddItem("Average HP");
		healingOptions.AddItem("Lowest HP");
		RedFogGroup.AddSpinner('spinnerHealing', "Red Fog Healing Type", "Red Fog Healing Type", healingOptions, RedFog_HealingType, SpinnerSaveLoggerHealing);

		// Hidden Potential Settings
		HiddenPGroup = Page.AddGroup('hiddenp', "Hidden Potential Settings");
		HiddenPGroup.AddSlider('SliderPercentGuaranteedStat', "Random Levelup Strength", "Random Levelup Strength", 0, 1, 0, HiddenP_PercentGuaranteedStat, SliderSaveLoggerPercentGuaranteedStat);

		// Weapon Roulette Settings
		WeaponRGroup = Page.AddGroup('weaponr', "Weapon Roulette Settings");
		WeaponRGroup.AddSlider('SliderDamageRange', "Damage Range", "Damage Range", 0, 100, 5, WeaponR_DamageRange, SliderSaveLoggerDamageRange);

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