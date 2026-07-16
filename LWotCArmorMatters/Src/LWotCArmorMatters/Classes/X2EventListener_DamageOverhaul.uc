class X2EventListener_DamageOverhaul extends X2EventListener config(ArmorMatters);

var config bool ENABLE_LOGGING;
var config bool DAMAGE_OVERHAUL_ENABLED;

var config array<name> DAMAGE_IGNORES_ARMOR;
var config array<name> DAMAGE_IGNORES_ABLATIVE;
var config array<name> IRRELEVANT_DAMAGE_TYPES;

struct HealthConversionEntry {
    var name Name;
    var float AblativeFactor;
};
var config array<HealthConversionEntry> HEALTH_CONVERSION_ALIENS;
var config array<HealthConversionEntry> HEALTH_CONVERSION_ALIEN_GROUPS;
var config array<name> HEALTH_BUFF_ABILITIES;

struct DamageSwapEntry {
    var name Name;
    var name Type;
};
var config array<DamageSwapEntry> WEAPON_DAMAGE_SWAP;

struct DOTRescheduleEntry {
    var name DamageType;
    var GameRuleStateChange Schedule;
};
var config array<DOTRescheduleEntry> CHANGE_DOT_SCHEDULES;

static function EditUnits() {
    local X2CharacterTemplateManager TemplateManager;
    local array<X2DataTemplate> DiffTemplates;
    local X2DataTemplate DataTemplate, DiffTemplate;
    local X2CharacterTemplate Template;
    local HealthConversionEntry ConversionSpec;
    local int BaseHP, ConvertedHP, ConversionIndex;

    TemplateManager = class'X2CharacterTemplateManager'.static.GetCharacterTemplateManager();

    foreach TemplateManager.IterateTemplates(DataTemplate)
    {
        Template = X2CharacterTemplate(DataTemplate);
        if(Template == none || Template.bIsSoldier)
            continue;

        TemplateManager.FindDataTemplateAllDifficulties(Template.DataName, DiffTemplates);
        foreach DiffTemplates(DiffTemplate) {
            Template = X2CharacterTemplate(DiffTemplate);

            BaseHP = Template.CharacterBaseStats[eStat_HP];
            ConversionIndex = default.HEALTH_CONVERSION_ALIENS.Find('Name', Template.DataName);
            if (ConversionIndex != -1)
            {
                `LOG("Damage Overhaul: Applying conversion spec for " $ Template.DataName $ " to " $ Template.Name, default.ENABLE_LOGGING, 'LWotCArmorMatters');
                ConversionSpec = default.HEALTH_CONVERSION_ALIENS[ConversionIndex];
            }
            else {
                ConversionIndex = default.HEALTH_CONVERSION_ALIEN_GROUPS.Find('Name', Template.CharacterGroupName);
                if (ConversionIndex != -1) {
                    `LOG("Damage Overhaul: Applying conversion spec for " $ Template.CharacterGroupName $ " to template " $ Template.DataName, default.ENABLE_LOGGING, 'LWotCArmorMatters');
                    ConversionSpec = default.HEALTH_CONVERSION_ALIEN_GROUPS[ConversionIndex];
                }
            }

            if (ConversionIndex != -1 && ConversionSpec.AblativeFactor < 1 && ConversionSpec.AblativeFactor > 0) {
                ConvertedHP = BaseHP * ConversionSpec.AblativeFactor;
                Template.CharacterBaseStats[eStat_HP] -= ConvertedHP;
                Template.CharacterBaseStats[eStat_ShieldHP] += ConvertedHP;
                `LOG("---Applied ablative factor " $ ConversionSpec.AblativeFactor $ ", converting " $ ConvertedHP $ " of " $ BaseHP $ " to ablative and leaving " $ Template.CharacterBaseStats[eStat_HP] $ " base HP", default.ENABLE_LOGGING, 'LWotCArmorMatters');
            }
        }
    }
}

static function EditWeapons() {
    local DamageSwapEntry SwapEntry;
    local X2ItemTemplateManager ItemMgr;
    local X2ItemTemplate ItemTemplate;
    local X2WeaponTemplate Template;

    ItemMgr = class'X2ItemTemplateManager'.static.GetItemTemplateManager();
    
    foreach default.WEAPON_DAMAGE_SWAP(SwapEntry) {
        `LOG("Damage Overhaul: Attempting to swap weapon " $ SwapEntry.Name $ " to damage type " $ SwapEntry.Type, default.ENABLE_LOGGING, 'LWotCArmorMatters');

        ItemTemplate = ItemMgr.FindItemTemplate(SwapEntry.Name);
        if(ItemTemplate == none) {
            `LOG("---Item does not exist", default.ENABLE_LOGGING, 'LWotCArmorMatters');
            continue;
        }

        Template = X2WeaponTemplate(ItemTemplate);
        if(Template == none) {
            `LOG("---Item is not a weapon", default.ENABLE_LOGGING, 'LWotCArmorMatters');
            continue;
        }

        Template.BaseDamage.DamageType = SwapEntry.Type;
    }
}

static function EditAbilities() {
    local name AbilityName;
    local X2AbilityTemplateManager TemplateManager;
    local X2DataTemplate Template;
    local X2AbilityTemplate AbilityTemplate;
    local X2Effect Effect, TickEffect;
    local X2Effect_Persistent PersistentEffect;
    local X2Effect_PersistentStatChange StatChangeEffect;
    local X2Effect_ApplyWeaponDamage DamageEffect;
    local int i, OriginalLength, RescheduleIndex;
    local StatChange StatChange, NewStatChange;
    local DOTRescheduleEntry RescheduleEntry;

    TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

    foreach TemplateManager.IterateTemplates(Template) {
        AbilityTemplate = X2AbilityTemplate(Template);

        if(AbilityTemplate == none) {
            continue;
        }

        if(default.HEALTH_BUFF_ABILITIES.Find(AbilityTemplate.DataName) != -1) {
            `LOG("Damage Overhaul: Attempting to update ability " $ AbilityTemplate.DataName $ " to add shield HP multiplier", default.ENABLE_LOGGING, 'LWotCArmorMatters');

            foreach AbilityTemplate.AbilityTargetEffects(Effect) {
                StatChangeEffect = X2Effect_PersistentStatChange(Effect);

                if(StatChangeEffect == none)
                    continue;
                OriginalLength = StatChangeEffect.m_aStatChanges.Length;
                    
                for(i = 0; i < OriginalLength; i++) {
                    StatChange = StatChangeEffect.m_aStatChanges[i];
                    if(StatChange.StatType != eStat_HP || StatChange.ModOp == MODOP_Addition)
                        continue;
                        
                    NewStatChange.StatAmount = StatChange.StatAmount;
                    NewStatChange.ApplicationRule = StatChange.ApplicationRule;
                    NewStatChange.ModOp = StatChange.ModOp;                  
                    NewStatChange.StatType = eStat_ShieldHP;
                    `LOG("------Added shield multiplier " $ NewStatChange.StatAmount $ " with operator " $ NewStatChange.ModOp, default.ENABLE_LOGGING, 'LWotCArmorMatters');
                    StatChangeEffect.m_aStatChanges.AddItem(NewStatChange);
                }
            }
        }

        foreach AbilityTemplate.AbilityTargetEffects(Effect) {
            PersistentEffect = X2Effect_Persistent(Effect);

            if(PersistentEffect == none)
                continue;
            
            foreach PersistentEffect.ApplyOnTick(TickEffect) {
                DamageEffect = X2Effect_ApplyWeaponDamage(TickEffect);

                if(DamageEffect == none)
                    continue;

                RescheduleIndex = default.CHANGE_DOT_SCHEDULES.Find('DamageType', DamageEffect.EffectDamageValue.DamageType);

                if(RescheduleIndex != -1) {
                    RescheduleEntry = default.CHANGE_DOT_SCHEDULES[RescheduleIndex];
                    `LOG("Damage Overhaul: Detected DoT with damage type " $ DamageEffect.EffectDamageValue.DamageType $ " in ability " $ AbilityTemplate.DataName $ ", setting to tick on " $ RescheduleEntry.Schedule, default.ENABLE_LOGGING, 'LWotCArmorMatters');
                    
                    PersistentEffect.WatchRule = RescheduleEntry.Schedule;
                }
            }
        }

        foreach AbilityTemplate.AbilityMultiTargetEffects(Effect) {
            PersistentEffect = X2Effect_Persistent(Effect);

            if(PersistentEffect == none)
                continue;
            
            foreach PersistentEffect.ApplyOnTick(TickEffect) {
                DamageEffect = X2Effect_ApplyWeaponDamage(TickEffect);

                if(DamageEffect == none)
                    continue;

                RescheduleIndex = default.CHANGE_DOT_SCHEDULES.Find('DamageType', DamageEffect.EffectDamageValue.DamageType);

                if(RescheduleIndex != -1) {
                    RescheduleEntry = default.CHANGE_DOT_SCHEDULES[RescheduleIndex];
                    `LOG("Damage Overhaul: Detected multi-target DoT with damage type " $ DamageEffect.EffectDamageValue.DamageType $ " in ability " $ AbilityTemplate.DataName $ ", setting to tick on " $ RescheduleEntry.Schedule, default.ENABLE_LOGGING, 'LWotCArmorMatters');
                    
                    PersistentEffect.WatchRule = RescheduleEntry.Schedule;
                }
            }
        }
    }
}