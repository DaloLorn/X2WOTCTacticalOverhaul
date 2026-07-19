//---------------------------------------------------------------------------------------
//  FILE:    X2DLCInfo_LWotCArmorMatters.uc
//  AUTHOR:  Iridar / Enhanced Mod Project Template --  26/02/2024
//  PURPOSE: Contains various DLC hooks, with examples on using the most popular ones.
//           Delete this file if you do not end up using it, as every class
//           that extends X2DownloadableContentInfo adds a tiny performance cost.
//---------------------------------------------------------------------------------------

class X2DLCInfo_LWotCArmorMatters extends X2DownloadableContentInfo config(ArmorMatters);

// Shared config
var config bool bEnableLog;

// Ablative Armor
var config bool bEnableAblativeArmor;
var config int iAdditionalAblative;
var config bool bStripArmorHP;
var config int iAblativeMultiplier;

// Ablative Plating
var config bool bEnableArmoredPlating;
var config bool bStripAblativePlating;

var config array<name> CERAMIC_PLATING_ABILITIES;
var config int CERAMIC_PLATING_ARMOR;

var config array<name> ALLOY_PLATING_ABILITIES;
var config int ALLOY_PLATING_ARMOR;

var config array<name> CHITIN_PLATING_ABILITIES;
var config int CHITIN_PLATING_ARMOR;

var config array<name> CARAPACE_PLATING_ABILITIES;
var config int CARAPACE_PLATING_ARMOR;

var config array<name> SPARK_KEVLAR_PLATING_ABILITIES;
var config int SPARK_KEVLAR_PLATING_ARMOR;

var config array<name> SPARK_PLATED_PLATING_ABILITIES;
var config int SPARK_PLATED_PLATING_ARMOR;

var config array<name> SPARK_POWERED_PLATING_ABILITIES;
var config int SPARK_POWERED_PLATING_ARMOR;

struct ArmoredPlatingEntry {
    var name Name;
    var int Armor;
};
var config array<ArmoredPlatingEntry> CUSTOM_PLATING_ABILITIES;

var localized string AblativeHP;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{}

static event OnPostTemplatesCreated()
{
	if(default.bEnableAblativeArmor) EditArmors();
    if(default.bEnableArmoredPlating) EditPlatings();
    if(`CoverDR.default.COVER_NO_DEFENSE_IN_MIN_RANGE) {
        class'CHHelpers'.static.GetCDO().AddOverrideCoverLevelCallback(OnOverrideCoverLevel);
        class'CHHelpers'.static.GetCDO().AddAdjustArmorMitigationCallback(OnAdjustArmorMitigation);
    }
    if(`CoverDR.default.COVER_DR_ENABLED) {
        `CoverDR`.static.EditAbilities();
    }
    if(`DamageOverhaul.default.DAMAGE_OVERHAUL_ENABLED) {
        `CHCDO.AddOverrideDefenseBypassCallback(OnOverrideDefenseBypass);
        `DamageOverhaul.static.EditUnits();
        `DamageOverhaul.static.EditWeapons();
        `DamageOverhaul.static.EditAbilities();
    }
}
static function EditArmors()
{
    local X2ItemTemplateManager ItemTemplateMgr;
    local array<X2DataTemplate> DiffTemplates;
    local X2DataTemplate DataTemplate, DiffTemplate;
    local X2ArmorTemplate EqTemplate, ArmorTemplate;
    local int i, TotalAblative, TotalHPMarkUps;

    ItemTemplateMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();

    foreach ItemTemplateMgr.IterateTemplates(DataTemplate, none)
    {
        `LOG("DataTemplate = " $ DataTemplate $ " Class Name = " $ DataTemplate.Class.Name, default.bEnableLog, 'LWotCArmorMatters');

        EqTemplate = X2ArmorTemplate(DataTemplate);        
        if ( EqTemplate != none )
        {            
            `LOG("EqTemplate = " $ EqTemplate, default.bEnableLog, 'LWotCArmorMatters');
            // Converts all HP bonuses to Ablative (if not done already)
            // and then returns total HP bonuses for display on UI
            TotalHPMarkUps = ConvertHPToAblative(EqTemplate.Abilities);            
            
            `LOG("---TotalHPMarkUps = " $ TotalHPMarkUps, default.bEnableLog, 'LWotCArmorMatters');
            if (TotalHPMarkUps < 0) continue;

            `LOG("------Updating UI stats", default.bEnableLog, 'LWotCArmorMatters');
            ItemTemplateMgr.FindDataTemplateAllDifficulties(EqTemplate.DataName, DiffTemplates);            
            foreach DiffTemplates(DiffTemplate)
            {
                `LOG("------DiffTemplate = " $ DiffTemplate, default.bEnableLog, 'LWotCArmorMatters');
                ArmorTemplate = X2ArmorTemplate(DiffTemplate);
                
                if (default.iAdditionalAblative > 0)
                {
                    `LOG("---------Additional ablative: " $ default.iAdditionalAblative * default.iAblativeMultiplier, default.bEnableLog, 'LWotCArmorMatters');
                    TotalAblative = TotalHPMarkUps + default.iAdditionalAblative * default.iAblativeMultiplier;
                    ArmorTemplate.Abilities.AddItem('DL_AblativeArmor');
                }
                else
                {
                    `LOG("---------Additional ablative: " $ default.iAdditionalAblative, default.bEnableLog, 'LWotCArmorMatters');
                    TotalAblative = TotalHPMarkUps;
                }

                `LOG("---------Set UI for eStat_ShieldHP: " $ TotalAblative, default.bEnableLog, 'LWotCArmorMatters');
                ArmorTemplate.SetUIStatMarkup(default.AblativeHP, eStat_ShieldHP, TotalAblative);

                if (default.bStripArmorHP)
                {    
                    for( i = 0; i < ArmorTemplate.UIStatMarkups.Length; i++ )
                    {
                        if (ArmorTemplate.UIStatMarkups[i].StatType == eStat_HP)
                        {
                            `LOG("------------Remove UI for eStat_HP", default.bEnableLog, 'LWotCArmorMatters');
                            ArmorTemplate.UIStatMarkups.Remove(i, 1); i--;
                        }
                    }
                }
                else
                {
                    `LOG("------------Retaining UI for eStat_HP", default.bEnableLog, 'LWotCArmorMatters');
                }
            }          
        }
    }
}

static function EditPlatings() {
    local name AbilityName;
    local ArmoredPlatingEntry PlatingEntry;

    foreach default.CERAMIC_PLATING_ABILITIES(AbilityName) {
        EditPlating(AbilityName, default.CERAMIC_PLATING_ARMOR);
    }
    foreach default.ALLOY_PLATING_ABILITIES(AbilityName) {
        EditPlating(AbilityName, default.ALLOY_PLATING_ARMOR);
    }
    foreach default.CHITIN_PLATING_ABILITIES(AbilityName) {
        EditPlating(AbilityName, default.CHITIN_PLATING_ARMOR);
    }
    foreach default.CARAPACE_PLATING_ABILITIES(AbilityName) {
        EditPlating(AbilityName, default.CARAPACE_PLATING_ARMOR);
    }
    foreach default.SPARK_KEVLAR_PLATING_ABILITIES(AbilityName) {
        EditPlating(AbilityName, default.SPARK_KEVLAR_PLATING_ARMOR);
    }
    foreach default.SPARK_PLATED_PLATING_ABILITIES(AbilityName) {
        EditPlating(AbilityName, default.SPARK_PLATED_PLATING_ARMOR);
    }
    foreach default.SPARK_POWERED_PLATING_ABILITIES(AbilityName) {
        EditPlating(AbilityName, default.SPARK_POWERED_PLATING_ARMOR);
    }
    foreach default.CUSTOM_PLATING_ABILITIES(PlatingEntry) {
        EditPlating(PlatingEntry.Name, PlatingEntry.Armor);
    }
}

static function EditPlating(name AbilityName, int ArmorBonus) {
    local X2AbilityTemplateManager AbilityMgr;
    local X2AbilityTemplate AbilityTemplate;
    local X2Effect_BonusArmor ArmorEffect;
    local X2Effect Effect;
    local X2Effect_PersistentStatChange StatEffect;
    local StatChange StatChange;
    local int i;

    `LOG("Armored Plating: attempting to edit " $ AbilityName, default.bEnableLog, 'LWotCArmorMatters');

    AbilityMgr = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

	AbilityTemplate = AbilityMgr.FindAbilityTemplate(AbilityName);
	if(none != AbilityTemplate)
	{
        if(default.bStripAblativePlating) {
            `LOG("---Stripping ablative HP from " $ AbilityName, default.bEnableLog, 'LWotCArmorMatters');
            foreach AbilityTemplate.AbilityTargetEffects(Effect) {
                StatEffect = X2Effect_PersistentStatChange(Effect);
                if(none != StatEffect) {
                    for( i = 0; i < StatEffect.m_aStatChanges.Length; i++) {
                        StatChange = StatEffect.m_aStatChanges[i];
                        if(StatChange.StatType == eStat_ShieldHP) {
                            `LOG("------Found ablative HP effect with value " $ StatChange.StatAmount, default.bEnableLog, 'LWotCArmorMatters');

                            if(StatChange.StatAmount > 0) {
                                StatEffect.m_aStatChanges.Remove(i, 1);
                                i--;
                            }
                        }
                    }
                }
            }
        }

        if(ArmorBonus > 0) {
            `LOG("---Adding " $ ArmorBonus $ " armor to " $ AbilityName, default.bEnableLog, 'LWotCArmorMatters');

            ArmorEffect = new class'X2Effect_BonusArmor';
            ArmorEffect.BuildPersistentEffect(1, true, false, false);
            ArmorEffect.ArmorMitigationAmount = ArmorBonus;
            AbilityTemplate.AddTargetEffect(ArmorEffect);
            AbilityTemplate.SetUIStatMarkup(class'XLocalizedData'.default.ArmorLabel, eStat_ArmorMitigation, ArmorBonus);
        }
	}
    else {
        `LOG("---Ability not found, skipping", default.bEnableLog, 'LWotCArmorMatters');
    }
}

static function int ConvertHPToAblative(array<name> Abilities)
{    
    local int i, j, TotalHPMarkUpsForAbility, TotalHPMarkUps, TotalAblative;
    local X2AbilityTemplateManager AbilityTemplateManager;
    local X2AbilityTemplate AbilityTemplate;
    local X2Effect Effect;
    local X2Effect_PersistentStatChange Effect_PersistentStatChange;
    local StatChange StatChange;

    AbilityTemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();    
    
    TotalHPMarkUps = 0; //init
    TotalAblative = 0;

    `LOG("---Abilities.Length = " $ Abilities.Length, default.bEnableLog, 'LWotCArmorMatters');
    for( i = 0; i < Abilities.Length; i++ )
    {
        AbilityTemplate = AbilityTemplateManager.FindAbilityTemplate(Abilities[i]);

        if (AbilityTemplate != none)
        {   
            `LOG("------AbilityTemplate = " $ AbilityTemplate, default.bEnableLog, 'LWotCArmorMatters');     
            
            foreach AbilityTemplate.AbilityTargetEffects(Effect)            
            {                
                Effect_PersistentStatChange = X2Effect_PersistentStatChange(Effect);
                if (Effect_PersistentStatChange != none)
                {
                    `LOG("---------Effect_PersistentStatChange = " $ Effect_PersistentStatChange, default.bEnableLog, 'LWotCArmorMatters');
                    
                    TotalHPMarkUpsForAbility = 0; //init
                    for( j = 0; j < Effect_PersistentStatChange.m_aStatChanges.Length; j++)
                    {
                        StatChange = Effect_PersistentStatChange.m_aStatChanges[j];
                        `LOG("------------StatChange = " $ StatChange.StatType $ ":" $ StatChange.StatAmount, default.bEnableLog, 'LWotCArmorMatters');
                                                
                        if (StatChange.StatType == eStat_HP && StatChange.StatAmount <= 0)
                        {
                            continue;
                        }
                        
                        if (StatChange.StatType == eStat_HP)
                        {                            
                            TotalHPMarkUps += StatChange.StatAmount;
                            TotalHPMarkUpsForAbility += StatChange.StatAmount;
                            
                            //Remove StatChange if its eStat_HP
                            if (default.bStripArmorHP)
                            {
                                `LOG("------------Removing " $ StatChange.StatType $ ":" $ StatChange.StatAmount, default.bEnableLog, 'LWotCArmorMatters');
                                Effect_PersistentStatChange.m_aStatChanges.Remove(j, 1); j--;
                            }
                            else
                            {
                                `LOG("------------Retaining " $ StatChange.StatType $ ":" $ StatChange.StatAmount, default.bEnableLog, 'LWotCArmorMatters');   
                            }
                        }                
                        if (StatChange.StatType == eStat_ShieldHP) {
                            TotalAblative += StatChange.StatAmount;
                        }
                    }

                    if (TotalHPMarkUpsForAbility > 0)
                    {
                        //Replace what was removed with ablative                        
                        if (default.iAblativeMultiplier > 1)
                        {                            
                            TotalHPMarkUpsForAbility = Round(TotalHPMarkUpsForAbility * default.iAblativeMultiplier);
                            `LOG("------------iAblativeMultiplier applied to TotalHPMarkUpsForAbility: " $ default.iAblativeMultiplier $ ": " $ TotalHPMarkUpsForAbility, default.bEnableLog, 'LWotCArmorMatters');
                        }                        
                        Effect_PersistentStatChange.AddPersistentStatChange(eStat_ShieldHP, TotalHPMarkUpsForAbility);
                        `LOG("------------Added eStat_ShieldHP: " $ TotalHPMarkUpsForAbility, default.bEnableLog, 'LWotCArmorMatters');
                    }
                }
            }
        }
    }
    
    if (default.iAblativeMultiplier > 1 && TotalHPMarkUps > 0)
    {
        TotalHPMarkUps = Round(TotalHPMarkUps * default.iAblativeMultiplier);
        `LOG("------iAblativeMultiplier applied to TotalHPMarkUps: " $ default.iAblativeMultiplier $ ": " $ TotalHPMarkUps, default.bEnableLog, 'LWotCArmorMatters');
    } 
    return TotalHPMarkUps + TotalAblative;
}

/*****************
 *** DELEGATES ***
 *****************/

static function EHLDelegateReturn OnOverrideCoverLevel(XComGameState_Unit UnitState, XComGameState_Unit TargetState, out GameRulesCache_VisibilityInfo VisInfo, Object EventSource) {
    local ECoverType TargetCover;

    if (EventSource.IsA(`CoverDR.Name))
    {
		`LOG("OnOverrideCoverLevel: ABORT - Event is internal!", `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        return EHLDR_NoInterrupt;
    }

    `LOG("OnOverrideCoverLevel: Received event from a " $ EventSource.Class.Name $ " with cover level " $ VisInfo.TargetCover, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');

    if (TargetState.IsDead() || TargetState.IsBleedingOut())
    {
		`LOG("OnOverrideCoverLevel: ABORT - Target is dead or dying!", `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        return EHLDR_NoInterrupt;
    }

    VisInfo.TargetCover = `CoverDR.static.EvalMinimumCoverDistance(VisInfo.TargetCover, UnitState, TargetState);

    `LOG("OnOverrideCoverLevel: Cover level after minimums is " $ VisInfo.TargetCover, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');

    return EHLDR_NoInterrupt;
}


static function EHLDelegateReturn OnAdjustArmorMitigation(int WeaponDamage, out int ArmorMitigation, out int ArmorPiercing, out int MinMitigation, EffectAppliedData ApplyEffectParams, X2Effect_ApplyWeaponDamage DamageEffect, optional bool IsMinDamagePreview, optional XComGameState GameState) {
    local ECoverType TargetCover;
    local float CoverDR, CoverDRMult;
    local int NetCoverDR;
    local StateObjectReference EffectRef;
    local X2Effect_Persistent Effect;

    local XComGameState_Unit kSourceUnit, kTarget;
    local XComGameState_Ability kAbility;
    local Array<Vector> HitLocations;
    local bool IsDamagePreview;
    
    local XComGameStateHistory History;
    local X2AbilityToHitCalc_StandardAim StandardAim;

    History = `XCOMHISTORY;

    if(GameState == none) {
        `LOG("OnAdjustArmorMitigation: Preview event received with args: WeaponDamage = " $ WeaponDamage $ ", ArmorMitigation = " $ ArmorMitigation $ ", ArmorPiercing = " $ ArmorPiercing $ ", MinMitigation = " $ MinMitigation $ ", SourceID = " $ ApplyEffectParams.SourceStateObjectRef.ObjectID $ ", TargetID = " $ ApplyEffectParams.TargetStateObjectRef.ObjectID $ ", AbilityID = " $ ApplyEffectParams.AbilityStateObjectRef.ObjectID $ ", IsMinDamagePreview = " $ IsMinDamagePreview, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
    }

    kSourceUnit = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParams.SourceStateObjectRef.ObjectID));
    kTarget = XComGameState_Unit(History.GetGameStateForObjectID(ApplyEffectParams.TargetStateObjectRef.ObjectID));
    kAbility = XComGameState_Ability(History.GetGameStateForObjectID(ApplyEffectParams.AbilityStateObjectRef.ObjectID));

    if(GameState != none) {
        kTarget = XComGameState_Unit(GameState.GetGameStateForObjectID(ApplyEffectParams.TargetStateObjectRef.ObjectID));
    }

    if(kSourceUnit == none || kTarget == none || kAbility == none || kTarget.IsDead() || kTarget.IsBleedingOut())
    {
		`LOG("OnAdjustArmorMitigation: ABORT - Event objects are invalid!", `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');

        if(GameState == none) {
            `LOG("OnAdjustArmorMitigation: Preview event exited with args: WeaponDamage = " $ WeaponDamage $ ", ArmorMitigation = " $ ArmorMitigation $ ", ArmorPiercing = " $ ArmorPiercing $ ", MinMitigation = " $ MinMitigation $ ", SourceID = " $ ApplyEffectParams.SourceStateObjectRef.ObjectID $ ", TargetID = " $ ApplyEffectParams.TargetStateObjectRef.ObjectID $ ", AbilityID = " $ ApplyEffectParams.AbilityStateObjectRef.ObjectID $ ", IsMinDamagePreview = " $ IsMinDamagePreview, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        }
        else {
            kTarget.SetUnitFloatValue('DL_NetCoverDR', 0);
            kTarget.SetUnitFloatValue('DL_CoverLevel', 0);
        }
        return EHLDR_NoInterrupt;
    }

    if(GameState == none) {
        `LOG("OnAdjustArmorMitigation: Preview event objects are: Source = " $ kSourceUnit.GetFullName() $ ", Target = " $ kTarget.GetFullName() $ ", Ability = " $ kAbility.GetMyTemplate().DataName, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
    }

    CoverDRMult = 1;
    StandardAim = X2AbilityToHitCalc_StandardAim(kAbility.GetMyTemplate().AbilityToHitCalc);
	if (!`CoverDR.default.COVER_DR_AFFECTS_MELEE && ((StandardAim != none && StandardAim.bMeleeAttack) || kAbility.GetMyTemplate().AbilityTargetStyle.IsA('X2AbilityTarget_MovingMelee')))
	{
		`LOG("OnAdjustArmorMitigation: ABORT - Is a melee attack!", `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');

        if(GameState == none) {
            `LOG("OnAdjustArmorMitigation: Preview event exited with args: WeaponDamage = " $ WeaponDamage $ ", ArmorMitigation = " $ ArmorMitigation $ ", ArmorPiercing = " $ ArmorPiercing $ ", MinMitigation = " $ MinMitigation $ ", SourceID = " $ ApplyEffectParams.SourceStateObjectRef.ObjectID $ ", TargetID = " $ ApplyEffectParams.TargetStateObjectRef.ObjectID $ ", AbilityID = " $ ApplyEffectParams.AbilityStateObjectRef.ObjectID $ ", IsMinDamagePreview = " $ IsMinDamagePreview, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        }
        else {
            kTarget.SetUnitFloatValue('DL_NetCoverDR', 0);
            kTarget.SetUnitFloatValue('DL_CoverLevel', 0);
        }
		return EHLDR_NoInterrupt;
	}
    if(StandardAim != none && (StandardAim.bIgnoreCoverBonus || kSourceUnit.HasAbilityFromAnySource('ARFMPYP_StationaryTyrants')))
    {
        `LOG("OnAdjustArmorMitigation: ABORT - Attack ignores cover bonuses!", `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');

        if(GameState == none) {
            `LOG("OnAdjustArmorMitigation: Preview event exited with args: WeaponDamage = " $ WeaponDamage $ ", ArmorMitigation = " $ ArmorMitigation $ ", ArmorPiercing = " $ ArmorPiercing $ ", MinMitigation = " $ MinMitigation $ ", SourceID = " $ ApplyEffectParams.SourceStateObjectRef.ObjectID $ ", TargetID = " $ ApplyEffectParams.TargetStateObjectRef.ObjectID $ ", AbilityID = " $ ApplyEffectParams.AbilityStateObjectRef.ObjectID $ ", IsMinDamagePreview = " $ IsMinDamagePreview, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        }
        else {
            kTarget.SetUnitFloatValue('DL_NetCoverDR', 0);
            kTarget.SetUnitFloatValue('DL_CoverLevel', 0);
        }
        return EHLDR_NoInterrupt;
    }

    if (kSourceUnit.HasAbilityFromAnySource('F_SurgicalPrecision') && (StandardAim == none || !StandardAim.bReactionFire))
    {
        CoverDRMult -= 0.5;
    }
    if (kSourceUnit.HasAbilityFromAnySource('F_SensePanic') && (kTarget.IsPanicked() || kTarget.IsDisoriented() || kTarget.IsDazed() || kTarget.IsStunned()))
    {
        CoverDRMult -= 0.5;
    }
    if(StandardAim != none && StandardAim.bReactionFire)
    {
        if(kSourceUnit.HasAbilityFromAnySource('AHWHeavyMechtoidOverwatchPassive')) {
            `LOG("OnAdjustArmorMitigation: ABORT - Attack ignores cover bonuses!", `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
            if(GameState == none) {
                `LOG("OnAdjustArmorMitigation: Preview event exited with args: WeaponDamage = " $ WeaponDamage $ ", ArmorMitigation = " $ ArmorMitigation $ ", ArmorPiercing = " $ ArmorPiercing $ ", MinMitigation = " $ MinMitigation $ ", SourceID = " $ ApplyEffectParams.SourceStateObjectRef.ObjectID $ ", TargetID = " $ ApplyEffectParams.TargetStateObjectRef.ObjectID $ ", AbilityID = " $ ApplyEffectParams.AbilityStateObjectRef.ObjectID $ ", IsMinDamagePreview = " $ IsMinDamagePreview, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
            }
            else {
                kTarget.SetUnitFloatValue('DL_NetCoverDR', 0);
                kTarget.SetUnitFloatValue('DL_CoverLevel', 0);
            }
            return EHLDR_NoInterrupt;
        }
        if(kSourceUnit.HasAbilityFromAnySource('F_Opportunist'))
            CoverDRMult -= 0.5;
        if(kSourceUnit.AffectedByEffectNames.Find('IRI_X2Effect_SP_CoveringFireIgnoreCover_Effect_LW') != -1)
            CoverDRMult -= 0.66;
    }

    if(kSourceUnit.IsHunkeredDown())
        CoverDRMult += `CoverDR.default.HUNKER_DR_MODIFIER;

    foreach(kSourceUnit.AffectedByEffects(EffectRef)) {
        Effect = X2Effect_CoverDRModifier(XComGameState_Effect(History.GetGameStateForObjectID(EffectRef.ObjectID)).GetX2Effect());
        if(Effect == none)
            continue;
        CoverDRMult += Effect.Magnitude;
    }

    if(CoverDRMult <= 0) {
        `LOG("OnAdjustArmorMitigation: ABORT - DR multiplier is nonpositive, no DR remains!", `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        if(GameState == none) {
            `LOG("OnAdjustArmorMitigation: Preview event exited with args: WeaponDamage = " $ WeaponDamage $ ", ArmorMitigation = " $ ArmorMitigation $ ", ArmorPiercing = " $ ArmorPiercing $ ", MinMitigation = " $ MinMitigation $ ", SourceID = " $ ApplyEffectParams.SourceStateObjectRef.ObjectID $ ", TargetID = " $ ApplyEffectParams.TargetStateObjectRef.ObjectID $ ", AbilityID = " $ ApplyEffectParams.AbilityStateObjectRef.ObjectID $ ", IsMinDamagePreview = " $ IsMinDamagePreview, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        }
        else {
            kTarget.SetUnitFloatValue('DL_NetCoverDR', 0);
            kTarget.SetUnitFloatValue('DL_CoverLevel', 0);
        }
        return EHLDR_NoInterrupt;
    }

    HitLocations = ApplyEffectParams.AbilityInputContext.TargetLocations;
    IsDamagePreview = GameState == none;

    TargetCover = `CoverDR.static.GetCoverDRLevel(kSourceUnit, kTarget, kAbility.GetMyTemplate(), HitLocations, GameState == none);
    // It's a *tad* too soon to calculate against incoming damage,
    // as we may have to deal with explosive falloff possibly setting damage to zero...
    // but to be fair, that *is* consistent with regular armor!
    switch (TargetCover) {
        case CT_MidLevel:
            CoverDR = fmin(`CoverDR.default.COVER_DR_FLAT_LOW + WeaponDamage * `CoverDR.default.COVER_DR_PERCENT_LOW, `CoverDR.default.COVER_DR_MAX_LOW) * CoverDRMult;
            break;
        case CT_Standing:
            CoverDR = fmin(`CoverDR.default.COVER_DR_FLAT_HIGH + WeaponDamage * `CoverDR.default.COVER_DR_PERCENT_HIGH, `CoverDR.default.COVER_DR_MAX_HIGH) * CoverDRMult;
            break;
        default:
            if(GameState == none) {
                `LOG("OnAdjustArmorMitigation: Preview event returned with args: WeaponDamage = " $ WeaponDamage $ ", ArmorMitigation = " $ ArmorMitigation $ ", ArmorPiercing = " $ ArmorPiercing $ ", MinMitigation = " $ MinMitigation $ ", SourceID = " $ ApplyEffectParams.SourceStateObjectRef.ObjectID $ ", TargetID = " $ ApplyEffectParams.TargetStateObjectRef.ObjectID $ ", AbilityID = " $ ApplyEffectParams.AbilityStateObjectRef.ObjectID $ ", IsMinDamagePreview = " $ IsMinDamagePreview, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
            }
            else {
                kTarget.SetUnitFloatValue('DL_NetCoverDR', 0);
                kTarget.SetUnitFloatValue('DL_CoverLevel', 0);
            }
            return EHLDR_NoInterrupt;
    }
    NetCoverDR = int(CoverDR);

    // Handle fractional DR!
    if(IsDamagePreview) 
    {
        NetCoverDR = IsMinDamagePreview ? FCeil(CoverDR) : FFloor(CoverDR);
    }
    else if (DamageEffect.PlusOneDamage(int((CoverDR - NetCoverDR) * 100)))
    {
        NetCoverDR++;
    }

    // If cover DR is impenetrable, then the minimum mitigation
    // is no longer 0!
    if (`CoverDR.default.COVER_DR_IMPENETRABLE && NetCoverDR > 0)
    {
        MinMitigation += NetCoverDR;
    }
    `LOG("Cover DR! Multiplier: " $ CoverDRMult $ " Cover DR value: " $ NetCoverDR $ " Leftover armor piercing value: " $ ArmorPiercing - ArmorMitigation, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');

    ArmorMitigation += NetCoverDR;

    if(GameState == none) {
        `LOG("OnAdjustArmorMitigation: Preview event returned with args: WeaponDamage = " $ WeaponDamage $ ", ArmorMitigation = " $ ArmorMitigation $ ", ArmorPiercing = " $ ArmorPiercing $ ", MinMitigation = " $ MinMitigation $ ", SourceID = " $ ApplyEffectParams.SourceStateObjectRef.ObjectID $ ", TargetID = " $ ApplyEffectParams.TargetStateObjectRef.ObjectID $ ", AbilityID = " $ ApplyEffectParams.AbilityStateObjectRef.ObjectID $ ", IsMinDamagePreview = " $ IsMinDamagePreview, `CoverDR.default.ENABLE_LOGGING, 'LWotCArmorMatters');
    }
    else {
        kTarget.SetUnitFloatValue('DL_NetCoverDR', max(MinMitigation, NetCoverDR - (ArmorPiercing - (ArmorMitigation - NetCoverDR))));
        kTarget.SetUnitFloatValue('DL_CoverLevel', TargetCover);
    }
    return EHLDR_NoInterrupt;
}

static function EHLDelegateReturn OnOverrideDefenseBypass(array<name> AppliedDamageTypes, out int bIgnoreArmor, out int bIgnoreShields, EffectAppliedData ApplyEffectParams, X2Effect_ApplyWeaponDamage DamageEffect, optional XComGameState NewGameState) {
    local name DamageType;

    foreach AppliedDamageTypes(DamageType) {
        if(`DamageOverhaul.default.IRRELEVANT_DAMAGE_TYPES.Find(DamageType) == -1)
            break;
        `LOG("OnOverrideDefenseBypass: Ignored irrelevant damage type " $ DamageType, `DamageOverhaul.default.ENABLE_LOGGING, 'LWotCArmorMatters');
    }

    `LOG("OnOverrideDefenseBypass: Detected primary damage type " $ DamageType $ ", extra type " $ DamageEffect.EffectDamageValue.DamageType, `DamageOverhaul.default.ENABLE_LOGGING, 'LWotCArmorMatters');
    if (`DamageOverhaul.default.DAMAGE_IGNORES_ARMOR.Find(DamageType) != -1 || `DamageOverhaul.default.DAMAGE_IGNORES_ARMOR.Find(DamageEffect.EffectDamageValue.DamageType) != -1)
        bIgnoreArmor = 1;
    if (`DamageOverhaul.default.DAMAGE_IGNORES_ABLATIVE.Find(DamageType) != -1 || `DamageOverhaul.default.DAMAGE_IGNORES_ABLATIVE.Find(DamageEffect.EffectDamageValue.DamageType) != -1)
        bIgnoreShields = 1;
    foreach AppliedDamageTypes(DamageType) {
        `LOG("OnOverrideDefenseBypass: Detected damage type " $ DamageType, `DamageOverhaul.default.ENABLE_LOGGING, 'LWotCArmorMatters');
    }

    foreach DamageEffect.DamageTypes(DamageType) {
        `LOG("OnOverrideDefenseBypass: Detected ability damage type " $ DamageType, `DamageOverhaul.default.ENABLE_LOGGING, 'LWotCArmorMatters');
        if(`DamageOverhaul.default.DAMAGE_IGNORES_ARMOR.Find(DamageType) != -1)
            bIgnoreArmor = 1;
        if(`DamageOverhaul.default.DAMAGE_IGNORES_ABLATIVE.Find(DamageType) != -1)
            bIgnoreShields = 1;
    }

    `LOG("OnOverrideDefenseBypass: Armor bypass is " $ bool(bIgnoreArmor) $ ", ablative bypass is " $ bool(bIgnoreShields), `DamageOverhaul.default.ENABLE_LOGGING, 'LWotCArmorMatters');

    return EHLDR_NoInterrupt;
}

