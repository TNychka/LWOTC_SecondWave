//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_AIReinforcementSpawner_LWOTC
//  AUTHOR:  Daniel Mitchell / LWOTC
//
//  PURPOSE: Override to have a new trigger
//--------------------------------------------------------------------------------------- 

class X2DownloadableContentInfo_LWOTC extends X2DownloadableContentInfo;

static function UpdateUIOnDifficultyMenuOpen(UIShellDifficulty UIShellDifficulty)
{

}

static function UpdateUIOnDifficultyChange(UIShellDifficulty UIShellDifficulty)
{

}

static function int AddSecondWaveOption(SecondWaveOption Option, string Description, string ToolTip)
{
	local array<Object>			UIShellDifficultyArray;
	local Object				ArrayObject;
	local UIShellDifficulty		UIShellDifficulty;
	local int					OptionIndex;

	UIShellDifficultyArray = class'XComEngine'.static.GetClassDefaultObjects(class'UIShellDifficulty');
	foreach UIShellDifficultyArray(ArrayObject)
	{
		UIShellDifficulty = UIShellDifficulty(ArrayObject);
		OptionIndex = UIShellDifficulty.SecondWaveOptions.Length;
		UIShellDifficulty.SecondWaveOptions.AddItem(Option);
		UIShellDifficulty.SecondWaveDescriptions.AddItem(Description);
		UIShellDifficulty.SecondWaveToolTips.AddItem(ToolTip);
	}
	return OptionIndex;
}