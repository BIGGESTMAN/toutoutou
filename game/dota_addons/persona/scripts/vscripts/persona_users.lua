require "personas"

LinkLuaModifier("modifier_persona_range_bonus", "modifier_persona_range_bonus", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_persona_health_bonus", "modifier_persona_health_bonus", LUA_MODIFIER_MOTION_NONE )
-- LinkLuaModifier("modifier_persona_speed_bonus", "modifier_persona_speed_bonus", LUA_MODIFIER_MOTION_NONE )


function Spawn(keys)
	local caster = keys.caster
	local ability = keys.ability
	local arcana = keys.arcana
	caster.arcana = arcana

	local startingPersona = nil
	for personaName,persona in pairs(personas_table) do
		if persona["arcana"] == arcana then
			startingPersona = personaName
			break
		end
	end

	local personaItem = CreateItem("item_"..startingPersona, caster, caster)
	caster:AddItem(personaItem)
	personaItem = InitializePersona(personaItem)

	caster:AddNewModifier(caster, ability, "modifier_persona_range_bonus", {})
	caster:AddNewModifier(caster, ability, "modifier_persona_health_bonus", {})
	-- caster:AddNewModifier(caster, ability, "modifier_persona_speed_bonus", {})
	caster:CastAbilityImmediately(personaItem, caster:GetPlayerID())

	local personaItemAngelTest = CreateItem("item_angel", caster, caster)
	caster:AddItem(personaItemAngelTest)
	personaItemAngelTest = InitializePersona(personaItemAngelTest)
end