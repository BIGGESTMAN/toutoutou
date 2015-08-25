function spellCast(keys)
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local ability = keys.ability

	local team = caster:GetTeamNumber()
	local origin = caster_location
	local radius = ability:GetSpecialValueFor("radius")
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local enemy_targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	iType = DOTA_UNIT_TARGET_HERO
	local enemy_heroes = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local ally_heroes = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local ally_targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	local damage = ability:GetSpecialValueFor("damage_per_target") * #ally_heroes
	local damage_type = ability:GetAbilityDamageType()
	local healing = ability:GetSpecialValueFor("damage_per_target") * #enemy_heroes

	for k,unit in pairs(enemy_targets) do
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
	end
	for k,unit in pairs(ally_targets) do
		unit:Heal(healing, caster)
	end

	DebugDrawCircle(origin, Vector(180,40,40), 1, radius, true, 0.2)

	-- local particle = ParticleManager:CreateParticle("particles/shikieiki/last_judgment.vpcf", PATTACH_ABSORIGIN, target)
	-- ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	-- ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_origin", target:GetAbsOrigin(), true)
	-- ParticleManager:SetParticleControlEnt(particle, 3, target, PATTACH_POINT, "attach_origin", target:GetAbsOrigin(), true)
end