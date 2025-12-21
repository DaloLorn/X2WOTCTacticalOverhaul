class X2Ability_AblativeToArmor extends X2Ability;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateAblativeHPAbility('DL_AblativeArmor', class'X2DLCInfo_LWotCArmorMatters'.default.iAdditionalAblative * class'X2DLCInfo_LWotCArmorMatters'.default.iAblativeMultiplier));	

	return Templates;
}

static function X2AbilityTemplate CreateAblativeHPAbility(name TemplateName, int AblativeHPAmt)
{
	local X2AbilityTemplate                 Template;
	local X2Effect_PersistentStatChange		AblativeHP;

	`CREATE_X2ABILITY_TEMPLATE(Template, TemplateName);

	Template.AbilitySourceName = 'eAbilitySource_Item';
	Template.Hostility = eHostility_Neutral;
	Template.AbilityToHitCalc = default.DeadEye;
	Template.AbilityTargetStyle = default.SelfTarget;
	Template.AbilityTriggers.AddItem(default.UnitPostBeginPlayTrigger);
	Template.bShowActivation=false;
	Template.bDisplayInUITacticalText = false;
	Template.bIsPassive = true;
	Template.bCrossClassEligible = false;
	Template.eAbilityIconBehaviorHUD = EAbilityIconBehavior_NeverShow;

	AblativeHP = new class'X2Effect_PersistentStatChange';
	AblativeHP.BuildPersistentEffect(1, true, false, false);
	AblativeHP.AddPersistentStatChange(eStat_ShieldHP, AblativeHPAmt);

	Template.AddTargetEffect(AblativeHP);
	Template.SetUIStatMarkup(class'X2DLCInfo_LWotCArmorMatters'.default.AblativeHP, eStat_ShieldHP, AblativeHPAmt);
	Template.BuildNewGameStateFn = TypicalAbility_BuildGameState;

	return Template;
}