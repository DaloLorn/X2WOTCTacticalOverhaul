# XCOM 2: War of the Chosen: Tactical Overhaul

A collection of highly configurable modules intended to heavily alter the rules of tactical combat in XCOM 2: War of the Chosen, taking some inspiration from the Long War Rebalance mod for XCOM: Enemy Within.

Developed in the LWotC/Mod Jam/Ted Jam environment, but *should* function in other contexts (e.g. vanilla or Covert Infiltration) if appropriate configs are provided, as most rule-changing mods revolve around the strategy layer.

This mod is intended to be experienced as-is, with the default configs and in tandem with the following extra mods:

- TeslaRage's [Ablative Vests](https://steamcommunity.com/sharedfiles/filedetails/?id=2335324263)
- NotSoLoneWolf's [Energy Shield Overhaul](https://steamcommunity.com/sharedfiles/filedetails/?id=2116145780)
- NotSoLoneWolf's [Damage Calculation Tweaks](https://steamcommunity.com/sharedfiles/filedetails/?id=2116144344)
- I also use TeslaRage's [Armour Upgrades](https://steamcommunity.com/sharedfiles/filedetails/?id=2644686699), but these are a bit janky (to put it mildly) with LWotC, *and* need extensive configuration to work with the myriad armors added in Ted Jam, so take it with a grain of salt.

However, these other mods are optional, and each of my modules can be configured and disabled separately. The modules are explained in more detail below.

## Ablative Armor

Makes XCOM's armor give ablative HP instead of regular HP, making armor upgrades increase the amount of damage you can soak before landing in the medbay (or suffering Red Fog), at the cost of limiting the effectiveness of healing in the late game.

For better compatibility with the Armored Plating module (see below), and as a (very small) bone to those who really need their soldiers to receive five full medkits' worth of healing to survive a mission, all armor (including kevlar) grants an extra +1 ablative HP.

This has been done before, on several occasions by different modders, e.g. Iridar's Armor Overhaul. However, those mods typically had unavoidable side effects, whereas this one is fully configurable and laser-focused on this specific functionality.

Implementation was reverse-engineered from TeslaRage's Ablative Vests mod.

## Armored Plating

Makes XCOM's platings (LW2 Utility Plating / LWotC) give 1/2/3/4 armor instead of ablative HP. In tandem with Ablative Armor/Vests, this module compels XCOM to put more effort into unlocking and deploying armor/vests across their roster to keep them out of the medbay. (Never before playing this mod have I seen fit to build any Nanoscale Vests except the freebie I got from the trooper autopsy...)

This also applies to any other items granting the plating abilities (e.g. Requiem's Stainless Alloy Plating, and - surprisingly enough - basically all the units in Buildable Units). Furthermore, it can be configured to do the same for any other ability containing a PersistentStatChange effect, removing all of its ablative HP (if any) in favor of an arbitrary amount of armor.

## Cover DR Redux

An extensive rewrite of Anisotropic's [Cover Damage Reduction](https://steamcommunity.com/sharedfiles/filedetails/?id=1126684731) mod, relying on a series of new Community Highlander features to provide better and more consistent results. (No longer will those pesky psi-bombing Codices be able to reduce mountains of Neural Feedback damage by hiding behind a wall!)

All config options from Anisotropic's mod have been migrated to this module, and several new options have been added on top, plus some fixes and balance changes:

- Cover DR is now a form of temporary armor, and subject to armor piercing and almost any armor-related interaction except (for obvious reasons) shredding.
  - Previously, any amount of armor piercing on an attack would simply deactivate cover DR. (What's more, if memory serves, attacks flagged to ignore armor outright would still be subject to cover DR...)
  - An optional config has been provided to make cover DR exempt from armor piercing, as in Long War Rebalance.
  - This also allows a new Highlander feature to account for cover DR when calculating how much damage an attack will do!
- Cover no longer provides any protection from direct attacks at close range, as in Long War Rebalance. (The target is essentially treated as flanked at that range.)
  - By default, low cover becomes ineffective at a distance of 2 tiles or closer, while high cover becomes ineffective at 1 tile or closer. (Diagonals are approximately 1.5 tiles long.)
  - Regardless of this feature, melee attacks are not affected by cover DR (unless configured otherwise, but that config is not guaranteed to work correctly).
- Cover now provides 30/50% percentile DR, as in Long War Rebalance, up from 0.33/1.0 flat DR. It is also limited to blocking a maximum of up to 8.0/16.0 damage.
- Abilities which reduce the effects of cover (e.g. Surgical Precision) have a proportional effect on cover DR where applicable. They also reduce maximum DR by the same percentage.

## Damage Overhaul

Taking all of the above mods and TO modules to their logical extreme, Damage Overhaul makes certain damage types ignore armor, ablative HP, or both to add depth to ADVENT's ability to hurt you... and then to make it a little fairer, makes most ADVENT units trade some HP for ablative HP!

- Psi, poison, bleeding, Elerium poison (from Bio Division), and Avatar Beam damage now bypasses all defenses and goes straight to HP. (Avatar Beam damage has also been configured to bypass energy shields!)
- Frost, fire, napalm, electrical, radiation, strangling (Requiem Seeker), and crushing (Viper bind) damage now bypasses ablative HP.
- XCOM's Psionic Reapers (ADVENT Psi Corps) and Warp Rifles (Expanded Playable Aliens) now deal Avatar Beam damage, in line with their visuals and lore.
- Tesla Rifles (Reshi's Tesla Trooper class) now deal electrical damage. (IIRC they already worked correctly when attacking, but reaction fire fired bullets styled as lightning bolts.)
- A *huge* amount of ADVENT units, both from the base game and from many mods seen in Tiaz and Tedster's respective sequels to the Mod Jam collection, have had anywhere from 0 to 75% of their HP pool converted to ablative HP.