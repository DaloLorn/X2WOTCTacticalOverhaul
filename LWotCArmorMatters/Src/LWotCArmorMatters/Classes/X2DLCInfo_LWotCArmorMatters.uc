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
                    ArmorTemplate.Abilities.AddItem('DL_AblativeForArmor');
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