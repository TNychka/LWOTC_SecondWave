//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_AIReinforcementSpawner_LWOTC
//  AUTHOR:  Daniel Mitchell / LWOTC
//
//  PURPOSE: Override to trigger events when difficulty is changed in the shell
//--------------------------------------------------------------------------------------- 

class Override_UIShellDifficulty extends UIShellDifficulty;

simulated function UpdateDifficulty(UICheckbox CheckboxControl)
{
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	local X2DownloadableContentInfo_LWOTC LWOTCDLCInfo;

	if( m_DifficultyRookieMechaItem.Checkbox.bChecked && m_DifficultyRookieMechaItem.Checkbox == CheckboxControl )
	{
		m_iSelectedDifficulty = 0;
	}
	else if( m_DifficultyVeteranMechaItem.Checkbox.bChecked && m_DifficultyVeteranMechaItem.Checkbox == CheckboxControl )
	{
		m_iSelectedDifficulty = 1;
	}
	else if( m_DifficultyCommanderMechaItem.Checkbox.bChecked && m_DifficultyCommanderMechaItem.Checkbox == CheckboxControl )
	{
		m_iSelectedDifficulty = 2;
	}
	else if( m_DifficultyLegendMechaItem.Checkbox.bChecked && m_DifficultyLegendMechaItem.Checkbox == CheckboxControl )
	{
		m_iSelectedDifficulty = 3;
	}

	m_DifficultyRookieMechaItem.Checkbox.SetChecked(m_iSelectedDifficulty == 0);
	m_DifficultyVeteranMechaItem.Checkbox.SetChecked(m_iSelectedDifficulty == 1);
	m_DifficultyCommanderMechaItem.Checkbox.SetChecked(m_iSelectedDifficulty == 2);
	m_DifficultyLegendMechaItem.Checkbox.SetChecked(m_iSelectedDifficulty == 3);

	if( m_iSelectedDifficulty >= 3 )
	{
		ForceTutorialOff();
	}
	else
	{
		GrantTutorialReadAccess();
	}

	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		LWOTCDLCInfo = X2DownloadableContentInfo_LWOTC(DLCInfo);
		if (LWOTCDLCInfo != none)
		{
			LWOTCDLCInfo.UpdateUIOnDifficultyChange(self);
		}
	}

	RefreshDescInfo();
}
