require "heroes/hero_murasa/throw_anchor"

function deepVortexCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel()
	local target_point = caster:GetAbsOrigin()

	local dummy_unit = CreateUnitByName("npc_dummy_unit", target_point, false, caster, caster, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, dummy_unit, keys.maelstrom_modifier, {})
	local particle = ParticleManager:CreateParticle(keys.particle, PATTACH_ABSORIGIN_FOLLOW, dummy_unit)
	ParticleManager:SetParticleControl(particle, 1, Vector(ability:GetLevelSpecialValueFor("radius", ability_level),0,0))

	local modifier = dummy_unit:FindModifierByName(keys.maelstrom_modifier)
	local ticks_dealt = 0
	modifier.units_stunned = {}

	local total_ticks = ability:GetLevelSpecialValueFor("duration", ability_level) / ability:GetLevelSpecialValueFor("damage_interval", ability_level)
	local damage = ability:GetLevelSpecialValueFor("total_damage", ability_level) / total_ticks

	Timers:CreateTimer(0, function()
		if not dummy_unit:IsNull() then
			local team = caster:GetTeamNumber()
			local origin = dummy_unit:GetAbsOrigin()
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER
			local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

			local physical_damage_percentage = ticks_dealt / total_ticks
			local magic_damage_percentage = 1 - physical_damage_percentage
			local physical_damage = physical_damage_percentage * damage
			local magic_damage = magic_damage_percentage * damage

			for k,unit in pairs(targets) do
				ApplyDamage({victim = unit, attacker = caster, damage = physical_damage, damage_type = DAMAGE_TYPE_PHYSICAL})
				ApplyDamage({victim = unit, attacker = caster, damage = magic_damage, damage_type = DAMAGE_TYPE_MAGICAL})
			end

			ticks_dealt = ticks_dealt + 1

			return ability:GetLevelSpecialValueFor("damage_interval", ability_level)
		end
	end)

	Timers:CreateTimer(ability:GetLevelSpecialValueFor("duration", ability_level), function()
		dummy_unit:RemoveSelf()
	end)

	if caster:HasScepter() then
		local anchor_ability = caster:FindAbilityByName("foundering_anchor")
		if anchor_ability then
			local anchors = ability:GetLevelSpecialValueFor("scepter_anchors", ability_level)
			local caster_location = caster:GetAbsOrigin()
			for i=1,anchors do
				local vector = RotatePosition(Vector(0,0,0), QAngle(0,i * 360 / anchors,0), caster:GetForwardVector())
				local target = caster_location + vector * ability:GetLevelSpecialValueFor("radius", ability_level)
				DebugDrawCircle(target, Vector(255,64,64), 1, 50, false, 2)

				anchor(caster, anchor_ability, target)
			end
			caster.anchor_charges = anchor_ability:GetLevelSpecialValueFor("max_charges", anchor_ability:GetLevel())
		end
	end
end

function maelstromTick(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel()
	local dummy = keys.target
	local modifier = dummy:FindModifierByName("modifier_maelstrom")

	local team = caster:GetTeamNumber()
	local origin = dummy:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		ability:ApplyDataDrivenModifier(caster, unit, keys.slow_modifier, {})
	end

	local center_radius = ability:GetLevelSpecialValueFor("center_radius", ability_level)

	targets = FindUnitsInRadius(team, origin, nil, center_radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		if not modifier.units_stunned[unit] then
			ability:ApplyDataDrivenModifier(caster, unit, keys.stunned_modifier, {})
			modifier.units_stunned[unit] = true
			local particle = ParticleManager:CreateParticle(keys.stun_particle, PATTACH_ABSORIGIN_FOLLOW, dummy)
		end
	end
end