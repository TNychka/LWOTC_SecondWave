//---------------------------------------------------------------------------------------
//  FILE:    X2DownloadableContentInfo_LWOTC_SecondWave
//  AUTHOR:  Daniel Mitchell / LWOTC
//
//  PURPOSE: Main mod file for LWOTC Second Wave Pack
//--------------------------------------------------------------------------------------- 

class X2DownloadableContentInfo_LWOTC_SecondWave extends LWOTCDownloadableContentInfo;

var localized string SignalReserves_Description;
var localized string SignalReserves_Tooltip;
var config int SignalReserves_ListPosition;

var localized string RedFog_Description;
var localized string RedFog_Tooltip;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{
	local XComGameState_Manager_RedFog RedFogManager;

	if(`SecondWaveEnabled('RedFog'))
	{
		`REDSCREEN("Red Fog Applied to game");
		RedFogManager = class'XComGameState_Manager_RedFog'.static.CreateModSettingsState_ExistingCampaign();
		RedFogManager.RegisterManager();
	}
}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed. When a new campaign is started the initial state of the world
/// is contained in a strategy start state. Never add additional history frames inside of InstallNewCampaign, add new state objects to the start state
/// or directly modify start state objects
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{
	local XComGameState_Manager_RedFog RedFogManager;

	if(`SecondWaveEnabled('RedFog'))
	{
		`REDSCREEN("Red Fog Applied to game");
		RedFogManager = class'XComGameState_Manager_RedFog'.static.CreateModSettingsState_NewCampaign(StartState);
		RedFogManager.RegisterManager();
	}
}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{

}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	AddRedFog();
	AddSignalReserves();
}

static function AddRedFog()
{
	local SecondWaveOption RedFog_Option;
	RedFog_Option.ID = 'RedFog';
	RedFog_Option.DifficultyValue = 0;
	AddSecondWaveOption(RedFog_Option, default.RedFog_Description, default.RedFog_Tooltip);
}

static function AddSignalReserves()
{
    local SecondWaveOption SignalReserves_Option;
	SignalReserves_Option.ID = 'SignalReserves';
	SignalReserves_Option.DifficultyValue = 0;
	default.SignalReserves_ListPosition = AddSecondWaveOption(SignalReserves_Option, default.SignalReserves_Description, default.SignalReserves_Tooltip);
}

static function UpdateUIOnDifficultyChange(UIShellDifficulty UIShellDifficulty)
{
	if (UIShellDifficulty.m_iSelectedDifficulty > 0)
	{
		UIMechaListItem(UIShellDifficulty.m_SecondWaveList.GetItem(default.SignalReserves_ListPosition)).Checkbox.SetChecked(false);
	}
	else
	{
		UIMechaListItem(UIShellDifficulty.m_SecondWaveList.GetItem(default.SignalReserves_ListPosition)).Checkbox.SetChecked(true);
	}
}