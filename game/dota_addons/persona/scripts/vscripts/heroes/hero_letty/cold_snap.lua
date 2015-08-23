function coldSnapCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local max_effects_time = ability:GetLevelSpecialValueFor("max_effects_time", ability_level)
	local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
	local scaling_damage = (ability:GetLevelSpecialValueFor("max_damage", ability_level) - base_damage) / max_effects_time
	local base_stun = ability:GetLevelSpecialValueFor("base_stun_duration", ability_level)
	local scaling_stun = (ability:GetLevelSpecialValueFor("max_stun_duration", ability_level) - base_stun) / max_effects_time
	local damage_type = ability:GetAbilityDamageType()

	-- Find ice field targets
	if not caster.lingering_cold_targets then caster.lingering_cold_targets = {} end
	for unit,v in pairs(caster.lingering_cold_targets) do
		if unit:IsNull() or not unit:IsAlive() then
			caster.lingering_cold_targets[unit] = nil
		end
	end
	local targets = caster.lingering_cold_targets

	-- Find direct targets
	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER

	local direct_targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(direct_targets) do
		targets[unit] = true
	end

	for unit,v in pairs(targets) do
		local damage = base_damage
		local stun_duration = base_stun
		local lingering_debuff = unit:FindModifierByName("modifier_lingering_cold_debuff")
		if lingering_debuff then
			local time_debuffed = GameRules:GetGameTime() - lingering_debuff.time_created
			if time_debuffed > max_effects_time then time_debuffed = max_effects_time end
			damage = damage + scaling_damage * time_debuffed
			stun_duration = stun_duration + scaling_stun * time_debuffed
		end
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_cold_snap_stun", {duration = stun_duration})

		local particle = ParticleManager:CreateParticle("particles/letty/cold_snap.vpcf", PATTACH_POINT_FOLLOW, unit)
		ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
	end

	local caster_circle_particle = ParticleManager:CreateParticle("particles/letty/cold_snap_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(caster_circle_particle, 1, Vector(radius,0,0))
	ParticleManager:SetParticleControlEnt(caster_circle_particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)

	if caster.ice_fields then
		for ice_field,v in pairs(caster.ice_fields) do
			if not ice_field:IsNull() then
				local field_circle_particle = ParticleManager:CreateParticle("particles/letty/cold_snap_circle.vpcf", PATTACH_ABSORIGIN_FOLLOW, ice_field)
				ParticleManager:SetParticleControl(field_circle_particle, 1, Vector(ice_field.radius,0,0))
				ParticleManager:SetParticleControlEnt(field_circle_particle, 0, ice_field, PATTACH_POINT_FOLLOW, "attach_hitloc", ice_field:GetAbsOrigin(), true)
			end
		end
	end
end