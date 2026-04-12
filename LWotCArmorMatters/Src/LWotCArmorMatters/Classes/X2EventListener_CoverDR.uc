class X2EventListener_CoverDR extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

    if(class'Helpers_CoverDR'.default.COVER_DR_ENABLED) {
        `ADD_EVENT_LISTENER(Templates, EditMitigationMessages, CoverDR);
        //Templates.AddItem(CreateCoverListener('EditMitigationMessages', 'DL_CoverDR_EditMitigationMessagesListener', OnEditMitigationMessages));
    }

	return Templates;
}

static function X2DataTemplate CreateCoverListener(name Event, name TemplateName, delegate<X2EventManager.OnEventDelegate> Handler) {
    return class'Helpers_EventListener'.static.CreateCHEventListener(Event, TemplateName, Handler);
}

static function EventListenerReturn OnEditMitigationMessages(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComLWTuple Message, Response;
    local X2Action_ApplyWeaponDamageToUnit DamageAction;
    local ECoverType UnitCover;
    local string CoverMessage;
    local int CoverDR;
    local array<XComLWTValueKind> ExpectedTypes;

    Message = XComLWTuple(EventData);
    ExpectedTypes.Length = 2;
    ExpectedTypes[0] = XComLWTVInt;
    ExpectedTypes[1] = XComLWTVArrayObjects;

	DamageAction = X2Action_ApplyWeaponDamageToUnit(EventSource);

	if (DamageAction == none || !class'Helpers_EventListener'.static.ValidateEvent(Message, 'EditMitigationMessages', ExpectedTypes, true))
    {
		`LOG("OnEditMitigationMessages: ABORT - Event is invalid!", class'Helpers_CoverDR'.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        return ELR_NoInterrupt;
    }
    
    if (DamageAction.TickContext != none || DamageAction.SourceUnitState == none || DamageAction.AbilityTemplate == none || DamageAction.AbilityContext == none)
    {
		`LOG("OnEditMitigationMessages: ABORT - Damage not caused by an attack!", class'Helpers_CoverDR'.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        return ELR_NoInterrupt;
    }

    // We shouldn't be computing this like that,
    // but I don't know how to properly pass the original DR
    // along from X2Effect_ApplyWeaponDamage. :(
    CoverDR = DamageAction.m_iMitigated - XComGameState_Unit(DamageAction.UnitState.GetPreviousVersion()).GetArmorMitigationForUnitFlag();
    `LOG("Mitigation = " $ DamageAction.m_iMitigated $ ", Armor = " $ XComGameState_Unit(DamageAction.UnitState.GetPreviousVersion()).GetArmorMitigationForUnitFlag() $ ", Shred = " $ DamageAction.m_iShredded $ ", Cover DR = " $ CoverDR, class'Helpers_CoverDR'.default.ENABLE_LOGGING, 'LWotCArmorMatters');

    if (CoverDR < 1)
    {
		`LOG("OnEditMitigationMessages: ABORT - Cover DR is nonpositive!", class'Helpers_CoverDR'.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        return ELR_NoInterrupt;
    }

    UnitCover = class'Helpers_CoverDR'.static.GetCoverDRLevel(XComGameState_Unit(DamageAction.SourceUnitState.GetPreviousVersion()), XComGameState_Unit(DamageAction.UnitState.GetPreviousVersion()), DamageAction.AbilityTemplate, DamageAction.AbilityContext.InputContext.TargetLocations, false, DamageAction.SourceUnitState.GetPreviousVersion().GetParentGameState().HistoryIndex);
    switch (UnitCover)
    {
        case CT_MidLevel:
            CoverMessage = Caps(class'XLocalizedData'.default.TargetLowCover);
            break;
        case CT_Standing:
            CoverMessage = Caps(class'XLocalizedData'.default.TargetHighCover);
            break;
        default:
            // This should never happen, so let's call it out!
            CoverMessage = "UNKNOWN COVER LEVEL";
            break;
    }
	
    Response = new class'XComLWTuple';
    Response.Id = 'ExtraMitigationMessage';
    Response.Data.Add(2);
    Response.Data[0].kind = XComLWTVString;
    Response.Data[0].s = CoverMessage;
    Response.Data[1].kind = XComLWTVInt;
    Response.Data[1].i = CoverDR;
    Message.Data[1].ao.AddItem(Response);

	return ELR_NoInterrupt;
}