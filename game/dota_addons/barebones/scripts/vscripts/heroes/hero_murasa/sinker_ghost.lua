LinkLuaModifier("modifier_sinker_ghost_enemies", "heroes/hero_murasa/modifier_sinker_ghost_enemies.lua", LUA_MODIFIER_MOTION_NONE )

function checkAttackSpeedRemoval(keys)
	if not keys.target:HasModifier(keys.drowned_modifier) then
		keys.attacker:RemoveModifierByName(keys.drowned_buff)
	end
end

function sinkerGhostModifierCreated(keys)
	keys.caster:AddNewModifier(keys.caster, keys.ability, "modifier_sinker_ghost_enemies", {})
end