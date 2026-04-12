class Helpers_EventListener extends Object;

static function bool ValidateEvent(XComLWTuple Message, name ExpectedID, array<XComLWTValueKind> ExpectedTypes, optional bool AllowExtraData = false, optional bool AllowMissingData = false) {
	local int i;

	`LOG("Event received: " $ ExpectedID, true,'LWotCArmorMatters');

	if(Message == none || (ExpectedId != '' && Message.Id != ExpectedID))
		return false;

	if(!AllowExtraData && Message.Data.Length > ExpectedTypes.Length)
		return false;

	if(!AllowMissingData && Message.Data.Length < ExpectedTypes.Length)
		return false;

	for(i = 0; i < ExpectedTypes.Length && i < Message.Data.Length; i++) {
		if(ExpectedTypes[i] != Message.Data[i].kind)
			return false;
	}

	return true;
}

static function CHEventListenerTemplate CreateCHEventListener(name Event, name TemplateName, delegate<X2EventManager.OnEventDelegate> Handler, optional bool RegisterInTactical = true, optional bool RegisterInCampaignStart = false, optional bool RegisterInStrategy = false, optional EventListenerDeferral Deferral = ELD_Immediate)
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, TemplateName);

	Template.AddCHEvent(Event, Handler, Deferral);

	Template.RegisterInTactical = RegisterInTactical;
    Template.RegisterInStrategy = RegisterInStrategy;
    Template.RegisterInCampaignStart = RegisterInCampaignStart;

	return Template;
}