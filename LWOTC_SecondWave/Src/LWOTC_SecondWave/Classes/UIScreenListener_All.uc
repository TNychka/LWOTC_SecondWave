class UIScreenListener_All extends UIScreenListener dependson(X2DownloadableContentInfo_LWOTC_SecondWave);

var bool CapturedDefaultBaseDamage;

defaultproperties
{
	// Leave this none so it can be triggered anywhere, gate inside the OnInit
	ScreenClass = none;
}

event OnInit(UIScreen Screen)
{
	if(UIShell(Screen) != none && !CapturedDefaultBaseDamage)  // this captures UIShell and UIFinalShell
	{
		// capture default spread settings for all weapons
		StoreDefaultWeaponBaseDamageValues();
		CapturedDefaultBaseDamage = true;
	}
}

function StoreDefaultWeaponBaseDamageValues()
{
	local X2ItemTemplateManager ItemTemplateManager;
	local X2WeaponTemplate Template;
	local array<X2WeaponTemplate> AllWeaponTemplates;
	local DefaultBaseDamageEntry BaseDamageEntry;
	local X2DownloadableContentInfo_LWOTC_SecondWave ModInfo;

	ModInfo = class'X2DownloadableContentInfo_LWOTC_SecondWave'.static.GetDLCInfo();
	if (ModInfo == none)
	{
		`REDSCREEN("LWOTC Second Wave : Unable to find X2DLCInfo");
		return;
	}

	//get access to item element template manager
	ItemTemplateManager = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
	if (ItemTemplateManager == none) {
		`Redscreen("LWOTC Second Wave : failed to retrieve ItemTemplateManager to capture Spread");
		return;
	}

	ModInfo.arrDefaultBaseDamage.Length = 0;

	AllWeaponTemplates = ItemTemplateManager.GetAllWeaponTemplates();
	
	foreach AllWeaponTemplates(Template)
	{
		BaseDamageEntry.WeaponTemplateName = Template.DataName;
		BaseDamageEntry.BaseDamage = Template.BaseDamage;
		ModInfo.arrDefaultBaseDamage.AddItem(BaseDamageEntry);
	}
}