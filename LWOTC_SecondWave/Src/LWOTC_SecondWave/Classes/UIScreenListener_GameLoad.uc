//---------------------------------------------------------------------------------------
//  FILE:    UIScreenListener_GameLoad
//  AUTHOR:  Amineri / Long War Studios
//
//  PURPOSE: Implements hooks to handle loads into tactical game, to make sure that toolbox options are loaded properly
//--------------------------------------------------------------------------------------- 

class UIScreenListener_GameLoad extends UIScreenListener;

// This event is triggered after a screen is initialized
event OnInit(UIScreen Screen)
{
	local XComGameState_Manager_RedFog RedFogManager;

	RedFogManager = class'XComGameState_Manager_RedFog'.static.GetRedFogManager();

	//re-register the hit point observer if necessary
	if(`SecondWaveEnabled('RedFog'))
	{
		RedFogManager.RegisterManager();
	}
}

// This event is triggered after a screen receives focus
//event OnReceiveFocus(UIScreen Screen);

// This event is triggered after a screen loses focus
//event OnLoseFocus(UIScreen Screen);

// This event is triggered when a screen is removed
//event OnRemoved(UIScreen Screen);

defaultproperties
{
	// AlienHunters update -- only have to listen for TacticalHUD, as strategy game is handled in X2DLCInfo
	ScreenClass = UITacticalHUD;
}
