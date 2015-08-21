Auto-Tooltip Generation Rules:
Ability description files should be .txt files placed in game/dota_addons/barebones/hero_abilities/ (ex: game/dota_addons/barebones/hero_abilities/Cirno - Strength (Ancient Apparition).txt)
Filename doesn't matter/is ignored, can be anything

Nothing before the first ability matters, but cannot contain a "["
In the formats below, anything listed as 'x' doesn't matter

Every ability must start with the format "[x] Name (internal name) : Description"

Every line in each ability description without parentheses will be ignored -- this normally includes devnotes, aghs descriptions, spell immunity details, and any ability numbers without specified internal names
	This also means parentheticals in stuff like devnotes won't work for now
Lines which will have associated tooltips must be in the format "Tooltip Text (internal abilityspecial name) : value".
	value can be anything, but cannot contain "(" -- this means scepter values using parentheses need to be changed to another character (curly braces, square braces, commas, whatever) or taken out for now
The internal abilityspecial names can be found in the ability .txt files -- in game/dota_addons/barebones/scripts/npc/abilities/
	If something needs a tooltip and doesn't have an abilityspecial, uh, bug me
The actual value for these tooltips will be drawn from said ability files. They will be automatically rendered into allcaps.

Exceptions: Lore and Notes are special.
Notes must be in the format "Note0 (Note0) : Note Text" (Or Note1, etc)
Lore must be in the format "Lore (Lore) : Lore Text"
Lore and Notes will not be rendered into allcaps.

See Cirno for an example