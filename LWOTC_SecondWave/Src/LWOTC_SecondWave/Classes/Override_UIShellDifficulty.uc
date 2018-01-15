//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_AIReinforcementSpawner_LWOTC
//  AUTHOR:  Daniel Mitchell / LWOTC
//
//  PURPOSE: Override to trigger events when difficulty is changed in the shell
//--------------------------------------------------------------------------------------- 

class Override_UIShellDifficulty extends UIShellDifficulty;

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local X2DownloadableContentInfo_LWOTC LWOTCDLCInfo;

	super.InitScreen(InitController, InitMovie, InitName);

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		LWOTCDLCInfo = X2DownloadableContentInfo_LWOTC(DLCInfo);
		if (LWOTCDLCInfo != none)
		{
			LWOTCDLCInfo.UpdateUIOnDifficultyMenuOpen(self);
		}
	}
}

simulated function UpdateDifficulty(UICheckbox CheckboxControl)
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local X2DownloadableContentInfo_LWOTC LWOTCDLCInfo;

	super.UpdateDifficulty(CheckboxControl);

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		LWOTCDLCInfo = X2DownloadableContentInfo_LWOTC(DLCInfo);
		if (LWOTCDLCInfo != none)
		{
			LWOTCDLCInfo.UpdateUIOnDifficultyChange(self);
		}
	}
}
