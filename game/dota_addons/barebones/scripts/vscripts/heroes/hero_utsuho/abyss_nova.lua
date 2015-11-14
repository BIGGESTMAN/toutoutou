LinkLuaModifier("modifier_abyss_nova_mana_gain_checker", "heroes/hero_utsuho/modifier_abyss_nova_mana_gain_checker.lua", LUA_MODIFIER_MOTION_NONE )

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_abyss_nova_active", {})
	caster:AddNewModifier(caster, ability, "modifier_abyss_nova_mana_gain_checker", {duration = ability:GetSpecialValueFor("duration")})
end

function restoreMana(keys)
	local caster = keys.caster
	local ability = keys.ability

	local base_mana_restore = ability:GetSpecialValueFor("base_mana_restore")
	local mana_restore_per_enemy = ability:GetSpecialValueFor("mana_restore_per_enemy")
	local mana_restore_per_hero = ability:GetSpecialValueFor("mana_restore_per_hero")
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local radius = ability:GetSpecialValueFor("radius")

	local units = 0
	local heroes = 0

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	DebugDrawCircle(origin, Vector(0,0,255), 1, radius, true, 0.03)
	for k,unit in pairs(targets) do
		if unit:IsRealHero() then
			heroes = heroes + 1
		else
			units = units + 1
		end
	end
	local mana_gain = (base_mana_restore + mana_restore_per_enemy * units + mana_restore_per_hero * heroes) * update_interval
	caster:SetMana(caster:GetMana() + mana_gain)
end

function removeManaGainChecker(keys)
	keys.caster:RemoveModifierByName("modifier_abyss_nova_mana_gain_checker")
end