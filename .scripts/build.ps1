Param(
    [string] $srcDirectory, # the path that contains your mod's .XCOM_sln
    [string] $sdkPath, # the path to your SDK installation ending in "XCOM 2 War of the Chosen SDK"
    [string] $gamePath, # the path to your XCOM 2 installation ending in "XCOM2-WaroftheChosen"
    [string] $config # build configuration
)

$ScriptDirectory = Split-Path $MyInvocation.MyCommand.Path
$common = Join-Path -Path $ScriptDirectory "X2ModBuildCommon\build_common.ps1"
Write-Host "Sourcing $common"
. ($common)

# Controls automatic project verification powered by Xymanek's X2ProjectGenerator.
# In order for this to have any effect, X2ProjectGenerator.exe must be in your PATH.
# To enable, set this flag to $true. To disable, set it back to $false.
$useX2PG = $false

if ($useX2PG -and $null -ne (Get-Command "X2ProjectGenerator.exe" -ErrorAction SilentlyContinue)) {
    Write-Host "Verifying project file..."
    &"X2ProjectGenerator.exe" "$srcDirectory\YOUR_MOD_NAME_HERE" "--exclude-contents" "--verify-only"
    if ($LASTEXITCODE -ne 0) {
        ThrowFailure "Errors in project file."
    }
}
else {
    Write-Host "Skipping verification of project file."
}

$builder = [BuildProject]::new("LWotCArmorMatters", $srcDirectory, $sdkPath, $gamePath)

# Building against Highlander option 1:
# Use Git to add Highlander submodule by running this command in the terminal:
# git submodule add https://github.com/X2CommunityCore/X2WOTCCommunityHighlander.git
# Uncomment the next line to enable building against Highlander.
# $builder.IncludeSrc("$srcDirectory\X2WOTCCommunityHighlander\X2WOTCCommunityHighlander\Src")

# Building against Highlander option 2:
# Specify path to your local Highlander repository or the Highlander's mod folder,
# and uncomment the line:
# $builder.IncludeSrc("C:\Users\Iridar\Documents\Firaxis ModBuddy\X2WOTCCommunityHighlander\X2WOTCCommunityHighlander\Src")

# Building against Highlander option 3:
# Create an X2EMPT_HIGHLANDER_FOLDER environment variable (if it does not already exist)
# containing the path to your local Highlander repository or the Highlander's mod folder,
# then uncomment the line:
$builder.IncludeSrc($env:X2EMPT_HIGHLANDER_FOLDER)

# Uncomment to use additional global Custom Src to build against.
# $builder.IncludeSrc("C:\Users\Iridar\Documents\Firaxis ModBuddy\CustomSrc")

switch ($config)
{
    "debug" {
        $builder.EnableDebug()
    }
    "default" {
        # Nothing special
    }
    "" { ThrowFailure "Missing build configuration" }
    default { ThrowFailure "Unknown build configuration $config" }
}

# Uncomment this line to enable cooking.
# $builder.SetContentOptionsJsonFilename("ContentOptions.json")
$builder.InvokeBuild()