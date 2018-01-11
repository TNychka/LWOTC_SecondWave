class X2DifficultyChangeListener_SecondWave extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	Templates.AddItem(CreateDifficultyChangeTemplate());
	return Templates;
}

static function X2EventListenerTemplate CreateDifficultyChangeTemplate()
{
	local X2EventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'X2EventListenerTemplate', Template, 'ChangeDifficultyToggleSecondWave');
	Template.AddEvent('OnShellDifficultyChange', ChangeDifficultyToggleSecondWave);
	`REDSCREEN("EventLoaded");

	return Template;
}

static protected function EventListenerReturn ChangeDifficultyToggleSecondWave(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local UIShellDifficulty DifficultyScreen;
	
	`REDSCREEN("EventTriggered");
	DifficultyScreen = UIShellDifficulty(EventSource);
	class'X2DownloadableContentInfo_LWOTC_Second_Wave'.static.SetTogglesOnShellDifficultyPage(DifficultyScreen);
	return ELR_NoInterrupt;
}