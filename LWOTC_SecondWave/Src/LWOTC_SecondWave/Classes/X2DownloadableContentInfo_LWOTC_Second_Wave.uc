class X2DownloadableContentInfo_LWOTC_Second_Wave extends X2DownloadableContentInfo;

var localized string SignalReserves_Description;
var localized string SignalReserves_Tooltip;

static event OnPostTemplatesCreated()
{
	UpdateSecondWaveOptionsList();
}


// Add the Pont-Based Not Created Equal option to the Second Wave Advanced Options list
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
		UIShellDifficulty.SecondWaveOptions.AddItem(SignalReserves_Option);
		UIShellDifficulty.SecondWaveDescriptions.AddItem(default.SignalReserves_Description);
		UIShellDifficulty.SecondWaveToolTips.AddItem(default.SignalReserves_Tooltip);
	}
}