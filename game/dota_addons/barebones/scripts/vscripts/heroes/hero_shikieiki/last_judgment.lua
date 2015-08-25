function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target
	local target_point = target:GetAbsOrigin()

	local radius = ability:GetSpecialValueFor("radius")

	local team = caster:GetTeamNumber()
	local origin = target_point
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	local total_guilt = 0
	for k,unit in pairs(targets) do
		if unit:HasModifier("modifier_not_guilty_debuff") then
			total_guilt = total_guilt + unit:FindModifierByName("modifier_not_guilty_debuff"):GetStackCount()
		end
	end

	local damage = ability:GetSpecialValueFor("base_damage") + total_guilt * ability:GetSpecialValueFor("bonus_damage")
	local damage_type = ability:GetAbilityDamageType()
	for k,unit in pairs(targets) do
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
	end

	DebugDrawCircle(origin, Vector(180,40,40), 0.5, radius, true, 0.2)

	local particle = ParticleManager:CreateParticle("particles/shikieiki/last_judgment.vpcf", PATTACH_ABSORIGIN, target)
	-- ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 1, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 3, target, PATTACH_POINT, "attach_hitloc", target:GetAbsOrigin(), true)
end