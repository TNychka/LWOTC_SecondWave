//---------------------------------------------------------------------------------------
//  FILE:    X2DownloadableContentInfo_LWOTC_SecondWave
//  AUTHOR:  Daniel Mitchell / LWOTC
//
//  PURPOSE: Main mod file for LWOTC Second Wave Pack
//--------------------------------------------------------------------------------------- 

class X2DownloadableContentInfo_LWOTC_SecondWave extends X2DownloadableContentInfo_LWOTC;

var localized string SignalReserves_Description;
var localized string SignalReserves_Tooltip;
var config int SignalReserves_ListPosition;

var localized string RedFog_Description;
var localized string RedFog_Tooltip;

var localized string HiddenP_Description;
var localized string HiddenP_Tooltip;

var localized string WeaponR_Description;
var localized string WeaponR_Tooltip;

struct DefaultBaseDamageEntry
{
	var name WeaponTemplateName;
	var WeaponDamageValue BaseDamage;
};
var transient array<DefaultBaseDamageEntry> arrDefaultBaseDamage;

static function X2DownloadableContentInfo_LWOTC_SecondWave GetDLCInfo()
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local X2DownloadableContentInfo_LWOTC_SecondWave ModInfo;

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		if (DLCInfo.DLCIdentifier == default.DLCIdentifier)
		{
			ModInfo = X2DownloadableContentInfo_LWOTC_SecondWave(DLCInfo);
			if (ModInfo != none)
				return ModInfo;
		}
	}
	return none;
}

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{
	local RedFog_XComGameState_Manager RedFogManager;
	local HiddenP_XComGameState_Manager HiddenPManager;
	local WeaponR_XComGameState_Manager WeaponRManager;

	if(`SecondWaveEnabled('RedFog'))
	{
		`REDSCREEN("Red Fog Applied to game");
		RedFogManager = RedFog_XComGameState_Manager(class'RedFog_XComGameState_Manager'.static.CreateModSettingsState_ExistingCampaign(class'RedFog_XComGameState_Manager'));
		RedFogManager.RegisterManager();
	}
	if(`SecondWaveEnabled('HiddenPotential'))
	{
		`REDSCREEN("Hidden Potential Applied to game");
		HiddenPManager = HiddenP_XComGameState_Manager(class'HiddenP_XComGameState_Manager'.static.CreateModSettingsState_ExistingCampaign(class'HiddenP_XComGameState_Manager'));
		HiddenPManager.RegisterManager();
	}

	WeaponRManager = WeaponR_XComGameState_Manager(class'WeaponR_XComGameState_Manager'.static.CreateModSettingsState_ExistingCampaign(class'WeaponR_XComGameState_Manager'));
	WeaponRManager.UpdateWeaponTemplates_RandomizedDamage();
}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed. When a new campaign is started the initial state of the world
/// is contained in a strategy start state. Never add additional history frames inside of InstallNewCampaign, add new state objects to the start state
/// or directly modify start state objects
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{
	local RedFog_XComGameState_Manager RedFogManager;
	local HiddenP_XComGameState_Manager HiddenPManager;
	local WeaponR_XComGameState_Manager WeaponRManager;

	if(`SecondWaveEnabled('RedFog'))
	{
		`REDSCREEN("Red Fog Applied to game");
		RedFogManager = RedFog_XComGameState_Manager(class'RedFog_XComGameState_Manager'.static.CreateModSettingsState_NewCampaign(class'RedFog_XComGameState_Manager', StartState));
		RedFogManager.RegisterManager();
	}
	if(`SecondWaveEnabled('HiddenPotential'))
	{
		`REDSCREEN("Hidden Potential Applied to game");
		HiddenPManager = HiddenP_XComGameState_Manager(class'HiddenP_XComGameState_Manager'.static.CreateModSettingsState_NewCampaign(class'HiddenP_XComGameState_Manager', StartState));
		HiddenPManager.RegisterManager();
	}

	WeaponRManager = WeaponR_XComGameState_Manager(class'WeaponR_XComGameState_Manager'.static.CreateModSettingsState_NewCampaign(class'WeaponR_XComGameState_Manager', StartState));
	WeaponRManager.UpdateWeaponTemplates_RandomizedDamage();
}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{
	local HiddenP_XComGameState_Manager HiddenPManager;

	if(`SecondWaveEnabled('HiddenPotential'))
	{
		HiddenPManager = class'HiddenP_XComGameState_Manager'.static.GetHiddenPotentialManager();
		HiddenPManager.PatchupMissingPCSStats();
		HiddenPManager.RegisterManager();
	}

	class'WeaponR_XComGameState_Manager'.static.GetWeaponRouletteManager().UpdateWeaponTemplates_RandomizedDamage();
}

/// <summary>
/// Called when the player completes a mission while this DLC / Mod is installed.
/// </summary>
static event OnPostMission()
{
	local HiddenP_XComGameState_Manager HiddenPManager;

	if(`SecondWaveEnabled('HiddenPotential'))
	{
		HiddenPManager = class'HiddenP_XComGameState_Manager'.static.GetHiddenPotentialManager();
		HiddenPManager.PatchupMissingPCSStats();
		HiddenPManager.RegisterManager();
	}
}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{
	AddRedFog();
	AddSignalReserves();
	AddHiddenPotential();
	AddWeaponRoulette();
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

static function AddHiddenPotential()
{
	local SecondWaveOption HiddenP_Option;
	HiddenP_Option.ID = 'HiddenPotential';
	HiddenP_Option.DifficultyValue = 0;
	AddSecondWaveOption(HiddenP_Option, default.HiddenP_Description, default.HiddenP_Tooltip);
}

static function AddWeaponRoulette()
{
	local SecondWaveOption WeaponR_Option;
	WeaponR_Option.ID = 'WeaponRoulette';
	WeaponR_Option.DifficultyValue = 0;
	AddSecondWaveOption(WeaponR_Option, default.WeaponR_Description, default.WeaponR_Tooltip);
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