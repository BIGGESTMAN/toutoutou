function yasakasDivineWindCast(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local radius = ability:GetLevelSpecialValueFor("knockback_range", ability_level)

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local damage_type = ability:GetAbilityDamageType()

	for k,unit in pairs(targets) do
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		ability:ApplyDataDrivenModifier(caster, unit, keys.modifier, {})
	end

	local particle = ParticleManager:CreateParticle(keys.particle, PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())

	local particle_interval = 1
	local particles_fired = 0
	Timers:CreateTimer(0, function()
		if particles_fired < ability:GetLevelSpecialValueFor("duration", ability_level) and caster:IsAlive() then
			local aura_particle = ParticleManager:CreateParticle("particles/yasakas_divine_wind.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControl(aura_particle, 1, caster:GetForwardVector() + caster:GetAbsOrigin())
			particles_fired = particles_fired + 1
			return particle_interval
		end
	end)
end

function knockback(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local speed = ability:GetLevelSpecialValueFor("knockback_speed", ability_level)
	local range = ability:GetLevelSpecialValueFor("knockback_range", ability_level)
	local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
	direction.z = 0
	local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()

	if distance < range then
		target:SetAbsOrigin(target:GetAbsOrigin() + direction * speed * 0.03)
		return 0.03
	else
		target:RemoveModifierByName("modifier_knocked_back")
		FindClearSpaceForUnit(target, target:GetAbsOrigin(), false)
	end
end

function slowAura(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local radius = ability:GetLevelSpecialValueFor("slow_radius", ability_level)
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		local unit_facing = unit:GetForwardVector()
		local direction_towards_caster = (unit:GetAbsOrigin() - origin):Normalized()
		local angle = unit_facing:Dot(direction_towards_caster)
		if angle < 0 then
			ability:ApplyDataDrivenModifier(caster, unit, keys.slow_modifier, {})
		end
	end
end