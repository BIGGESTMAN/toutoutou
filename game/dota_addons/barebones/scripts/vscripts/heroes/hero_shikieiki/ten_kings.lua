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

	for k,hero in pairs(ally_heroes) do
		if hero:IsIllusion() and not hero.cleansed_crystal_illusion then
			table.remove(ally_heroes, k)
		end
	end
	for k,hero in pairs(enemy_heroes) do
		if hero:IsIllusion() and not hero.cleansed_crystal_illusion then
			table.remove(enemy_heroes, k)
		end
	end
	local damage = ability:GetSpecialValueFor("damage_per_target") * #ally_heroes
	local damage_type = ability:GetAbilityDamageType()
	local healing = ability:GetSpecialValueFor("damage_per_target") * #enemy_heroes

	for k,unit in pairs(enemy_targets) do
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		local damage_particle = ParticleManager:CreateParticle("particles/shikieiki/ten_kings_damage.vpcf", PATTACH_POINT, caster)
		ParticleManager:SetParticleControlEnt(damage_particle, 0, caster, PATTACH_POINT, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(damage_particle, 1, unit, PATTACH_POINT, "attach_hitloc", unit:GetAbsOrigin(), true)
	end
	for k,unit in pairs(ally_targets) do
		unit:Heal(healing, caster)
		local healing_particle = ParticleManager:CreateParticle("particles/shikieiki/ten_kings_healing.vpcf", PATTACH_POINT, caster)
		ParticleManager:SetParticleControlEnt(healing_particle, 0, caster, PATTACH_POINT, "attach_hitloc", caster:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(healing_particle, 1, unit, PATTACH_POINT, "attach_hitloc", unit:GetAbsOrigin(), true)
	end

	-- DebugDrawCircle(origin, Vector(180,40,40), 1, radius, true, 0.2)

	local particle = ParticleManager:CreateParticle("particles/shikieiki/ten_kings_ground.vpcf", PATTACH_ABSORIGIN, caster)
	-- ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	-- ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_origin", target:GetAbsOrigin(), true)
	-- ParticleManager:SetParticleControlEnt(particle, 3, target, PATTACH_POINT, "attach_origin", target:GetAbsOrigin(), true)
end