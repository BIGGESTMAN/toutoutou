require "libraries/util"

function moonlightRay(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local start_radius = ability:GetLevelSpecialValueFor("start_radius", ability_level )
	local end_radius = ability:GetLevelSpecialValueFor("end_radius", ability_level )
	local end_distance = ability:GetLevelSpecialValueFor("range", ability_level )
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local damage_type = ability:GetAbilityDamageType()

	local caster_forward = caster:GetForwardVector()

	local cone_units = GetEnemiesInCone(caster, start_radius, end_radius, end_distance, caster_forward, 5)
	for _,unit in pairs(cone_units) do
		ApplyDamage({ victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		ability:ApplyDataDrivenModifier(caster, unit, keys.slow_modifier, {})

		unit.moonlight_ray_slowed_particle = ParticleManager:CreateParticle("particles/rumia/moonlight_ray_slow.vpcf", PATTACH_ABSORIGIN, unit)
		ParticleManager:SetParticleControlEnt(unit.moonlight_ray_slowed_particle, 1, unit, PATTACH_POINT, "attach_origin", unit:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(unit.moonlight_ray_slowed_particle, 3, unit, PATTACH_POINT, "attach_origin", unit:GetAbsOrigin(), true)
	end

	local dummy_unit = CreateUnitByName("npc_dota_invisible_vision_source", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_unit, keys.dummy_modifier, {})

	local vertical_distance = 75
	dummy_unit:SetAbsOrigin(caster:GetAbsOrigin() + Vector(0,0,vertical_distance))
	local angle = VectorToAngles(caster_forward)
	dummy_unit:SetAngles(90,angle.y,0)

	local particle = ParticleManager:CreateParticle(keys.particle_name, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlEnt(particle, 1, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 5, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 6, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
	-- time out particle dummy after a while
	Timers:CreateTimer(5, function()
		dummy_unit:RemoveSelf()
	end)
end

function checkBonusDamageProc(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local proc_modifier = keys.proc_modifier
	local damage = ability:GetLevelSpecialValueFor("bonus_damage", ability_level)
	local damage_type = ability:GetAbilityDamageType()

	if not caster:CanEntityBeSeenByMyTeam(target) and not target:HasModifier(proc_modifier) then
		ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
		ability:ApplyDataDrivenModifier(caster, target, proc_modifier, {})
		
		local particle = ParticleManager:CreateParticle("particles/rumia/moonlight_ray_slow_proc.vpcf", PATTACH_ABSORIGIN, target)
		ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT, "attach_origin", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 3, target, PATTACH_POINT, "attach_origin", target:GetAbsOrigin(), true)
	end
end

function removeSlowParticle(keys)
	ParticleManager:DestroyParticle(keys.target.moonlight_ray_slowed_particle, false)
	keys.target.moonlight_ray_slowed_particle = nil
end