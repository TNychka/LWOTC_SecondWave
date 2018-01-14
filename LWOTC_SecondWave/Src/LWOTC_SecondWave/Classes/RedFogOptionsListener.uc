class RedFogOptionsListener extends UIScreenListener config(LWOTC_RedFog);

`include(LWOTC_SecondWave/Src/ModConfigMenuAPI/MCM_API_Includes.uci)
`include(LWOTC_SecondWave/Src/ModConfigMenuAPI/MCM_API_CfgHelpers.uci)

var config bool EnabledAlien;
var config bool EnabledXcom;
var config bool IsLinear;
var config string PenaltyType;
var config string HealingType;
var config int CONFIG_VERSION;

defaultproperties
{
    ScreenClass = none;
}

`MCM_CH_VersionChecker(class'RedFogOptions_Defaults'.default.VERSION,CONFIG_VERSION)

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
    local MCM_API_SettingsGroup Group;
	local array<string> penaltyOptions, healingOptions;
    
    LoadSavedSettings();

	if (GameMode == eGameMode_MainMenu)
	{
		Page = ConfigAPI.NewSettingsPage("Red Fog Settings");
		Page.SetPageTitle("Red Fog Settings");
		Page.SetSaveHandler(SaveButtonClicked);
    
		Group = Page.AddGroup('group', "General Settings");
    
		Group.AddCheckbox('checkboxEnabledAliens', "Red Fog enabled for Advent", "Red Fog enabled for Advent", EnabledAlien, CheckboxSaveHandlerEnabledAliens);
		Group.AddCheckbox('checkboxEnabledXcom', "Red Fog enabled for XCOM", "Red Fog enabled for XCOM", EnabledXcom, CheckboxSaveHandlerEnabledXcom);
		Group.AddCheckbox('checkboxLinear', "Red Fog is linearly applied", "Alternative being Quadratic", IsLinear, CheckboxSaveHandlerLinear);

		penaltyOptions.Length = 0;
		penaltyOptions.AddItem("Additive");
		penaltyOptions.AddItem("Multiplicative");
		Group.AddSpinner('spinnerPenalty', "Red Fog Penalty Type", "Red Fog Penalty Type", penaltyOptions, PenaltyType, SpinnerSaveLoggerPenalty);


		healingOptions.Length = 0;
		healingOptions.AddItem("Current HP");
		healingOptions.AddItem("Average HP");
		healingOptions.AddItem("Lowest HP");
		Group.AddSpinner('spinnerHealing', "Red Fog Healing Type", "Red Fog Healing Type", healingOptions, HealingType, SpinnerSaveLoggerHealing);

    
		Page.ShowSettings();
	}
}

`MCM_API_BasicCheckboxSaveHandler(CheckboxSaveHandlerEnabledAliens, EnabledAlien)
`MCM_API_BasicCheckboxSaveHandler(CheckboxSaveHandlerEnabledXcom, EnabledXcom)
`MCM_API_BasicCheckboxSaveHandler(CheckboxSaveHandlerLinear, IsLinear)
`MCM_API_BasicSpinnerSaveHandler(SpinnerSaveLoggerPenalty, PenaltyType)
`MCM_API_BasicSpinnerSaveHandler(SpinnerSaveLoggerHealing, HealingType)

simulated function LoadSavedSettings()
{
    EnabledAlien = `MCM_CH_GetValue(class'RedFogOptions_Defaults'.default.EnabledAlien,EnabledAlien);
	EnabledXcom = `MCM_CH_GetValue(class'RedFogOptions_Defaults'.default.EnabledXcom,EnabledXcom);
	IsLinear = `MCM_CH_GetValue(class'RedFogOptions_Defaults'.default.IsLinear,IsLinear);
	PenaltyType = `MCM_CH_GetValue(class'RedFogOptions_Defaults'.default.PenaltyType,PenaltyType);
	HealingType = `MCM_CH_GetValue(class'RedFogOptions_Defaults'.default.HealingType,HealingType);
}

simulated function SaveButtonClicked(MCM_API_SettingsPage Page)
{
    self.CONFIG_VERSION = `MCM_CH_GetCompositeVersion();
    self.SaveConfig();
}