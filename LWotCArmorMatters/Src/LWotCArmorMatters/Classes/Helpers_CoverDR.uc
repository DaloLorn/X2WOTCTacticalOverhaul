class Helpers_CoverDR extends Object config(ArmorMatters);

var config bool COVER_DR_ENABLED;
var config bool COVER_DR_IMPENETRABLE;
var config bool COVER_DR_IGNORES_EXPLOSIONS;
var config bool COVER_DR_CALCULATES_EXPLOSIONS_FROM_ATTACKER;
var config bool COVER_DR_AFFECTS_MELEE;
var config bool COVER_NO_DEFENSE_IN_MIN_RANGE;

var config float COVER_DR_FLAT_LOW, COVER_DR_FLAT_HIGH;
var config float COVER_DR_PERCENT_LOW, COVER_DR_PERCENT_HIGH;
var config int COVER_DR_MAX_LOW, COVER_DR_MAX_HIGH;
var config int COVER_DR_MIN_RANGE_LOW, COVER_DR_MIN_RANGE_HIGH;

var config ECoverType COVER_DR_UNFLANKABLE_COVER_LEVEL;

var config bool PREVIEW_ARMOR_MITIGATION;
var config bool PREVIEW_ONLY_COVER_MITIGATION;
var config bool ENABLE_LOGGING;

// Helper function to compute whether a target should benefit from cover DR.
static simulated function ECoverType GetCoverDRLevel(XComGameState_Unit SourceUnit, Damageable kTarget, X2AbilityTemplate AbilityTemplate, Array<Vector> HitLocations, bool IsPreview = false, optional int HistoryIndex = -1)
{
	local GameRulesCache_VisibilityInfo VisInfo;
	local ECoverType TargetCover;
	local Vector TargetVector;
	local bool IsAreaOfEffect;
	local X2GameRulesetVisibilityManager VisibilityMgr;
	local bool CalculatedFromEpicenter;
	local X2AbilityToHitCalc_StandardAim HitCalc;
	local XComGameState_Unit TargetUnit;
	local XComGameState GameState;

	if(IsPreview) {
		`LOG("GetCoverDRLevel: Invoked by preview", default.ENABLE_LOGGING, 'LWotCArmorMatters');
	}

	// Early return: Is this even a unit?
	TargetUnit = XComGameState_Unit(kTarget);
	if (TargetUnit == none || TargetUnit.IsDead() || TargetUnit.IsBleedingOut())
	{
		`LOG("GetCoverDRLevel: ABORT - Not a living unit!", default.ENABLE_LOGGING, 'LWotCArmorMatters');
		return CT_None;
	}
	else if(IsPreview) {
		`LOG("GetCoverDRLevel: Unit is confirmed alive", default.ENABLE_LOGGING, 'LWotCArmorMatters');
	}

	// Early return: Is this unit associated with a game state?
	GameState = TargetUnit.GetParentGameState();
	if (GameState == none)
	{
		`LOG("GetCoverDRLevel: ABORT - No game state!", default.ENABLE_LOGGING, 'LWotCArmorMatters');
		return CT_None;
	}
	else if(IsPreview) {
		`LOG("GetCoverDRLevel: Game state exists", default.ENABLE_LOGGING, 'LWotCArmorMatters');
	}

	// Early return: Are we exempting melee from cover DR?
	HitCalc = X2AbilityToHitCalc_StandardAim(AbilityTemplate.AbilityToHitCalc);
	if (!default.COVER_DR_AFFECTS_MELEE && ((HitCalc != none && HitCalc.bMeleeAttack) || AbilityTemplate.AbilityTargetStyle.IsA('X2AbilityTarget_MovingMelee')))
	{
		`LOG("GetCoverDRLevel: ABORT - Is a melee attack!", default.ENABLE_LOGGING, 'LWotCArmorMatters');
		return CT_None;
	}
	else if(IsPreview) {
		`LOG("GetCoverDRLevel: Is not a melee attack", default.ENABLE_LOGGING, 'LWotCArmorMatters');
	}

	// Early return: Does this ability ignore cover bonuses?
	if (HitCalc != none && HitCalc.bIgnoreCoverBonus)
	{
		`LOG("GetCoverDRLevel: ABORT - Hit calculation ignores cover bonus!", default.ENABLE_LOGGING, 'LWotCArmorMatters');
		return CT_None;
	}
	else if(IsPreview) {
		`LOG("GetCoverDRLevel: Hit calculation does not ignore cover bonus", default.ENABLE_LOGGING, 'LWotCArmorMatters');
	}

	// Are we actually in cover? What's our cover bonus? We're about to find out.
	TargetCover = CT_None;
	CalculatedFromEpicenter = false;
	VisibilityMgr = `TACTICALRULES.VisibilityMgr;
	if (VisibilityMgr.GetVisibilityInfo(SourceUnit.ObjectID, TargetUnit.ObjectID, VisInfo, HistoryIndex))
	{
		TargetCover = VisInfo.TargetCover;

		// Explosive AoE handling
		IsAreaOfEffect = CheckIsExplosion(AbilityTemplate);
		if (IsAreaOfEffect)
		{
			if (HitLocations.Length == 1) 
			{
				// Early return: Are we exempting AoEs from cover DR?
				if (default.COVER_DR_IGNORES_EXPLOSIONS) 
				{
					`LOG("GetCoverDRLevel: ABORT - Ignoring explosions!", default.ENABLE_LOGGING,'LWotCArmorMatters');
					return CT_None;
				} 
				else if (!default.COVER_DR_CALCULATES_EXPLOSIONS_FROM_ATTACKER)
				{
					TargetVector = class'XComWorldData'.static.GetWorldData().GetPositionFromTileCoordinates(TargetUnit.TileLocation);
					CalculatedFromEpicenter = true;
					// Anisotropic's choice of angles here feels wrong, like it'll still be calculating against the attacker's position somehow...
					// but I'm not sure how to get a more appropriate angle... :(
					TargetCover = class'XComWorldData'.static.GetWorldData().GetCoverTypeForTarget(HitLocations[0], TargetVector, VisInfo.TargetCoverAngle);
				}
			}
		}
	}
	else
	{
		`LOG("GetCoverDRLevel: ABORT - No visibility info!", default.ENABLE_LOGGING,'LWotCArmorMatters');
		return CT_None;
	}

	// Unflankable units might get innate cover DR. Let's hope nobody uses this feature.
	if (!TargetUnit.GetMyTemplate().bCanTakeCover)
	{
		TargetCover = default.COVER_DR_UNFLANKABLE_COVER_LEVEL;
	}
	
	`LOG("GetCoverDRLevel: Evaluated cover level as " $ TargetCover, default.ENABLE_LOGGING,'LWotCArmorMatters');

	TargetCover = EvalMinimumCoverDistance(TargetCover, SourceUnit, TargetUnit, CalculatedFromEpicenter, HitLocations, TargetVector);

	`LOG("GetCoverDRLevel: Cover level after minimums is " $ TargetCover, default.ENABLE_LOGGING,'LWotCArmorMatters');

	return TargetCover;
}

// Helper function trying to check whether an ability's damage might not originate
// from the attacker's location.
// I am really glad Volt ignores armor, because I wouldn't know where to begin...
static simulated function bool CheckIsExplosion(X2AbilityTemplate AbilityTemplate)
{
	if (AbilityTemplate == none || AbilityTemplate.AbilityMultiTargetStyle == none)
	{
		return false;
	}

	if (AbilityTemplate.AbilityMultiTargetStyle.IsA('X2AbilityMultiTarget_Radius'))
	{
		return true;
	}

	return false;
}

// Helper function adjusting cover level for minimum cover range.
// The optional parameters are unused by hit calcs, as only a direct attack
// will be affected by defense.
static simulated function ECoverType EvalMinimumCoverDistance(ECoverType TargetCover, XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, optional bool CalculatedFromEpicenter = false, optional array<Vector> HitLocations, optional Vector TargetVector) 
{
	local int MinimumTiles;

	// Early return: The minimum range check is pointless if
	// we're not expecting cover bonuses anyway.
	if (TargetCover == CT_None)
	{
		`LOG("EvalCoverMinimumDistance: ABORT - Already out of cover!", default.ENABLE_LOGGING,'LWotCArmorMatters');
		return TargetCover;
	}

	// Get minimum distance to apply cover bonuses.
	switch (TargetCover) 
	{
		case CT_MidLevel:
			MinimumTiles = default.COVER_DR_MIN_RANGE_LOW;
			break;
		case CT_Standing:
			MinimumTiles = default.COVER_DR_MIN_RANGE_HIGH;
			break;
		default:
			return TargetCover;
	}

	// If AoE DR calculated from epicenter: Are we too close to the AoE for cover?
	// Disabled for now. Feels weird to be giving point-blank bonuses to a grenade, since
	// presumably the point-blank bonus signifies being able to effectively aim around/over cover...
	/*if (CalculatedFromEpicenter)
	{
		if (!IsEpicenterFarEnoughForCover(HitLocations[0], TargetVector, MinimumTiles))
		{
			TargetCover = CT_None;
		}
	}
	// If DR calculated from attacker position: Are we too close to the attacker for cover?
	else */if (!IsAttackerFarEnoughForCover(SourceUnit, TargetUnit, MinimumTiles))
	{
		TargetCover = CT_None;
	}

	return TargetCover;
}

// Helper function testing whether an attacker is far enough to suffer cover penalties.
static simulated function bool IsAttackerFarEnoughForCover(XComGameState_Unit SourceUnit, XComGameState_Unit TargetUnit, int MinimumTiles)
{
	// A tile distance less than 1 cannot ever count as "in cover" in the first place,
	// so setting a minimum cover range to such a value is another way of saying
	// "cover bonuses always apply".
	if (MinimumTiles < 1)
	{
		`LOG("IsAttackerFarEnoughForCover: ABORT - Always true!", default.ENABLE_LOGGING,'LWotCArmorMatters');
		return true;
	}
	
	// Cover only applies if we're more than MinimumTiles away.
	// For instance, taking LWR's Point Blank mechanic as an example:
	// MinimumTiles would be 1, so cover applies if we're 2+ tiles away.
	`LOG("IsAttackerFarEnoughForCover: Tile distance is " $ TargetUnit.TileDistanceBetween(SourceUnit), default.ENABLE_LOGGING,'LWotCArmorMatters');
	return TargetUnit.TileDistanceBetween(SourceUnit) > MinimumTiles;
}

// Helper function testing whether the epicenter of an AoE is far enough to suffer cover penalties.
// See IsAttackerFarEnoughForCover() for explanations.
static simulated function bool IsEpicenterFarEnoughForCover(Vector Epicenter, Vector TargetVector, int MinimumTiles)
{
	local XComWorldData World;
	local float Dist;
	local int Tiles;

	if (MinimumTiles < 1)
	{
		return true;
	}
	
	// Math shamelessly cribbed and condensed from XComGameState_Unit::TileDistanceBetween().
	World = `XWORLD;
	Dist = VSize(Epicenter - TargetVector);
	Tiles = Dist / World.WORLD_StepSize;
	`LOG("IsEpicenterFarEnoughForCover: Tile distance is " $ Tiles, default.ENABLE_LOGGING,'LWotCArmorMatters');
	return Tiles > MinimumTiles;
}

static function EditAbilities() {
    local name AbilityName;
    local X2AbilityTemplateManager TemplateManager;
    local X2DataTemplate Template;
    local X2AbilityTemplate AbilityTemplate;
    local X2Effect Effect, TickEffect;
    local X2Effect_Persistent PersistentEffect;
    local int i;
	local X2Effect_CoverDRModifier CoverDRModifier;

    TemplateManager = class'X2AbilityTemplateManager'.static.GetAbilityTemplateManager();

    foreach TemplateManager.IterateTemplates(Template) {
        AbilityTemplate = X2AbilityTemplate(Template);

        if(AbilityTemplate == none) {
            continue;
        }

		for(i = 0; i < AbilityTemplate.AbilityTargetEffects.Length; i++) {
			Effect = AbilityTemplate.AbilityTargetEffects[i];
			if(!Effect.IsA('AHW_Effect_MutonHardy'))
				continue;
            `LOG("Cover DR: Detected Hardy effect on ability " $ AbilityTemplate.DataName $ ", reconstructing as CoverDRModifier +0.5...", default.ENABLE_LOGGING, 'LWotCArmorMatters');
			PersistentEffect = X2Effect_Persistent(Effect);
			CoverDRModifier = new class'X2Effect_CoverDRModifier';
			CoverDRModifier.ClonePersistentEffect(PersistentEffect, 0.5);
			AbilityTemplate.AbilityTargetEffects[i] = CoverDRModifier;
		}

		for(i = 0; i < AbilityTemplate.AbilityMultiTargetEffects.Length; i++) {
			Effect = AbilityTemplate.AbilityMultiTargetEffects[i];
			if(!Effect.IsA('AHW_Effect_MutonHardy'))
				continue;
            `LOG("Cover DR: Detected multi-target Hardy effect on ability " $ AbilityTemplate.DataName $ ", reconstructing as CoverDRModifier +0.5...", default.ENABLE_LOGGING, 'LWotCArmorMatters');
			PersistentEffect = X2Effect_Persistent(Effect);
			CoverDRModifier = new class'X2Effect_CoverDRModifier';
			CoverDRModifier.ClonePersistentEffect(PersistentEffect, 0.5);
			AbilityTemplate.AbilityMultiTargetEffects[i] = CoverDRModifier;
		}
    }
}