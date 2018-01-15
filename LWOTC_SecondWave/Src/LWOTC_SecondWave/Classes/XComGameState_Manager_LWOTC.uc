class XComGameState_Manager_LWOTC extends XComGameState_BaseObject abstract;

function static XComGameState_Manager_LWOTC CreateModSettingsState_NewCampaign(class<XComGameState_Manager_LWOTC> NewClassType, XComGameState GameState)
{
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_Manager_LWOTC ManagerState;
	local bool bFoundExistingSettings;

	foreach GameState.IterateByClassType(class'XComGameState_CampaignSettings', CampaignSettingsStateObject)
	{
		break;
	}
	//check for existing ModOptions game state -- this should never happen here, but keeping the code intact just in case
	if(CampaignSettingsStateObject != none)
	{
		if(CampaignSettingsStateObject.FindComponentObject(NewClassType, false) != none)
			bFoundExistingSettings = true;
	}
	if(CampaignSettingsStateObject == none || bFoundExistingSettings)
	{
	}
	else
	{
		CampaignSettingsStateObject = XComGameState_CampaignSettings(GameState.CreateStateObject(class'XComGameState_CampaignSettings', CampaignSettingsStateObject.ObjectID));
		ManagerState = XComGameState_Manager_LWOTC(GameState.CreateStateObject(NewClassType));
		CampaignSettingsStateObject.AddComponentObject(ManagerState);
		GameState.AddStateObject(ManagerState);
		GameState.AddStateObject(CampaignSettingsStateObject);
		return ManagerState;
	}
	return none;
}

function static XComGameState_Manager_LWOTC CreateModSettingsState_ExistingCampaign(class<XComGameState_Manager_LWOTC> NewClassType)
{
	local XComGameStateHistory History;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState UpdateState;
	local XComGameState_Manager_LWOTC ManagerState;
	local bool bFoundExistingSettings;

	History = `XCOMHISTORY;
	UpdateState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Adding Manager");
	CampaignSettingsStateObject = XComGameState_CampaignSettings(History.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings'));
	//check for existing ModOptions game state
	if(CampaignSettingsStateObject != none)
	{
		if(CampaignSettingsStateObject.FindComponentObject(NewClassType, false) != none)
			bFoundExistingSettings = true;
	}
	if(CampaignSettingsStateObject == none || bFoundExistingSettings)
	{
		History.CleanupPendingGameState(UpdateState);
	}
	else
	{
		CampaignSettingsStateObject = XComGameState_CampaignSettings(UpdateState.CreateStateObject(class'XComGameState_CampaignSettings', CampaignSettingsStateObject.ObjectID));
		ManagerState = XComGameState_Manager_LWOTC(UpdateState.CreateStateObject(NewClassType));
		CampaignSettingsStateObject.AddComponentObject(ManagerState);
		UpdateState.AddStateObject(ManagerState);
		UpdateState.AddStateObject(CampaignSettingsStateObject);
		History.AddGameStateToHistory(UpdateState);
		return ManagerState;
	}
	return none;
}