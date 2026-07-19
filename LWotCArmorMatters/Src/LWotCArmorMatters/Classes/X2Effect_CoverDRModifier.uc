// Modifies the cover DR multiplier for an attack, increasing
// or decreasing DR by a percentage. Multiple effects stack.
// (... I think.)
class X2Effect_CoverDRModifier extends X2Effect_Persistent;

var privatewrite float Magnitude; 

// Helper function to use while OPTCing custom DR effects
// (such as Requiem's AHW_Effect_MutonHardy)
// into a format compatible with the cover DR system.
simulated function ClonePersistentEffect(X2Effect_Persistent Source, float _Magnitude) {
    Magnitude = _Magnitude;
    EffectName = Source.EffectName;

    iNumTurns = Source.iNumTurns;
    bInfiniteDuration = Source.bInfiniteDuration;
    bRemoveWhenSourceDies = Source.bRemoveWhenSourceDies;
    bIgnorePlayerCheckOnTick = Source.bIgnorePlayerCheckOnTick;
    WatchRule = Source.WatchRule;
    
    BuffCategory = Source.BuffCategory;
    FriendlyName = Source.FriendlyName;
    FriendlyDescription = Source.FriendlyDescription;
    IconImage = Source.IconImage;
    bDisplayInUI = Source.bDisplayInUI;
    StatusIcon = Source.StatusIcon;
    AbilitySourceName = Source.AbilitySourceName;

    SourceBuffCategory = Source.SourceBuffCategory;
    SourceFriendlyName = Source.SourceFriendlyName;
    SourceFriendlyDescription = Source.SourceFriendlyDescription;
    SourceIconLabel = Source.SourceIconLabel;
    bSourceDisplayInUI = Source.bSourceDisplayInUI;
}

DefaultProperties
{
    Magnitude=0.5
    EffectName="X2Effect_CoverDRModifier"
}