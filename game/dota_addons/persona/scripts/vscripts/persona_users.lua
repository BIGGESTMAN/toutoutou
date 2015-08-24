require "personas"

LinkLuaModifier("modifier_persona_range_bonus", "modifier_persona_range_bonus", LUA_MODIFIER_MOTION_NONE )

function Spawn(keys)
	local caster = keys.caster
	local ability = keys.ability
	local startingPersona = keys.persona

	local personaItem = CreateItem("item_"..startingPersona, caster, caster)
	caster:AddItem(personaItem)
	personaItem = InitializePersona(personaItem)

	caster:AddNewModifier(caster, ability, "modifier_persona_range_bonus", {})
	caster:CastAbilityImmediately(personaItem, caster:GetPlayerID())
end