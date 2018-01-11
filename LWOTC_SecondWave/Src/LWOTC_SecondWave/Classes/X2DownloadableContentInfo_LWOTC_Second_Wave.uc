class X2DownloadableContentInfo_LWOTC_Second_Wave extends X2DownloadableContentInfo;

var localized string SignalReserves_Description;
var localized string SignalReserves_Tooltip;
var config int SignalReserves_ListPosition;

static event OnPostTemplatesCreated()
{
	UpdateSecondWaveOptionsList();
}

static function UpdateSecondWaveOptionsList()
{
	local array<Object>			UIShellDifficultyArray;
	local Object				ArrayObject;
	local UIShellDifficulty		UIShellDifficulty;
    local SecondWaveOption		SignalReserves_Option;
	
	SignalReserves_Option.ID = 'SignalReserves';
	SignalReserves_Option.DifficultyValue = 0;

	UIShellDifficultyArray = class'XComEngine'.static.GetClassDefaultObjects(class'UIShellDifficulty');
	foreach UIShellDifficultyArray(ArrayObject)
	{
		UIShellDifficulty = UIShellDifficulty(ArrayObject);
		default.SignalReserves_ListPosition = UIShellDifficulty.SecondWaveOptions.Length;
		UIShellDifficulty.SecondWaveOptions.AddItem(SignalReserves_Option);
		UIShellDifficulty.SecondWaveDescriptions.AddItem(default.SignalReserves_Description);
		UIShellDifficulty.SecondWaveToolTips.AddItem(default.SignalReserves_Tooltip);
	}
}

static function SetTogglesOnShellDifficultyPage(UIShellDifficulty ShellDifficulty)
{
	if (ShellDifficulty.m_iSelectedDifficulty > 0)
	{
		UIMechaListItem(ShellDifficulty.m_SecondWaveList.GetItem(default.SignalReserves_ListPosition)).Checkbox.SetChecked(false);
	}
	else
	{
		UIMechaListItem(ShellDifficulty.m_SecondWaveList.GetItem(default.SignalReserves_ListPosition)).Checkbox.SetChecked(true);
	}
}