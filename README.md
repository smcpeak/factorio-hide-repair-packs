# Hide Repair Packs

Hide Repair Packs is a mod for [Factorio](https://wiki.factorio.com/).

## Problem

If the player has a personal roboport with repair packs in their
inventory, then whenever a nearby object takes damage, a robot will go
try to repair it.  When this happens during combat, as is common, the
robot will often be instantly killed by whatever damaged the object.
Then, since the object is still damaged (and probably taking more
damage), another robot will go and meet the same fate, etc.  Repairing
while the battle is raging is usually counterproductive.

A common tactic is to disable one's personal roboport during combat, but
then robots cannot be used to deploy turrets, clear paths through trees
and rocks, etc.

A better tactic is to temporarily put all of one's repair packs into the
trash inventory slots, then pull them back out after the battle to
safely conduct repairs, since robots will not take repair packs out of
the trash.  But that is tedious when combat is frequent and easily
forgotten when it is not.

## Solution

With this mod enabled, anytime the player is near an enemy (by default,
that means within 80 squares, but that is configurable), it will
automatically move all repair packs (and other items designated as
repair tools by their contributing mods) into the trash slots.  When the
player is no longer near any enemy, the repair packs are moved back into
the main inventory so that after-action repairs can be performed.

## Indicator of action

When nearby enemies are detected, and hence repair packs hidden in the
trash, an icon is shown in the upper left corner so the user understands
why their repair packs are moving.  This indicator can be disabled,
however.

## Performance considerations

The mod periodically scans for nearby enemies, by default once per
second (60 ticks).  Each scan takes about 50us on a medium size map (that
is just what I tested; I have not noticed a dependence on map size) with
the default range, for an amortized cost of about 1 us per tick.

The inventory check and transfers are only performed if the enemy scan
result (as a boolean) is different from the previous scan.  Since the
scan result changes very infrequently, those costs are negligible.

## Uninstallation

To uninstall, just remove the mod.  It does not add any entities or
other save-game state, so removal is non-destructive.

## Possible extensions

It would be desirable to extend this to work with regular roboports too
so they could be positioned near walls that frequently come under
attack.  However, some changes would have to be made to account for the
much larger number of places to scan, the lack of a convenient "trash"
slot in roboports, and for the fact that robots will potentially take
repair kits from anywhere in the logistic network.  I am not currently
planning on working on such an extension but might try if there is
interest.
