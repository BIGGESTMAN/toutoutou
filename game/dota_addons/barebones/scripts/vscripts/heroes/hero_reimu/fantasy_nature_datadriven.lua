LinkLuaModifier("modifier_fantasy_nature_alt", "heroes/hero_reimu/modifier_fantasy_nature_alt.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_fantasy_nature_stun", "heroes/hero_reimu/modifier_fantasy_nature_stun.lua", LUA_MODIFIER_MOTION_NONE )

function fantasyNatureStart(keys)

	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", caster)

	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	caster:AddNewModifier(caster, ability, "modifier_fantasy_nature_alt", {duration = duration})
end