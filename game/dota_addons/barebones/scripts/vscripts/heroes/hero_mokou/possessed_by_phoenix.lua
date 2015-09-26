function spellCast(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	ability:ApplyDataDrivenModifier(caster, target, "modifier_possessed_by_phoenix_active_effect", {})

	local health_cost = caster:GetHealth() * ability:GetSpecialValueFor("health_cost_percent") / 100
	ApplyDamage({victim = caster, attacker = caster, damage = health_cost, damage_type = DAMAGE_TYPE_PURE})
end

function passiveSpellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local triggering_ability = keys.event_ability

	if not triggering_ability:IsItem() then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_possessed_by_phoenix_passive_effect", {})
	end
end

function damagePulse(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local damage_interval = ability:GetSpecialValueFor("damage_interval")
	local max_missing_health_percent = ability:GetSpecialValueFor("damage_percent_max") * damage_interval
	local min_missing_health_percent = ability:GetSpecialValueFor("damage_percent_min") * damage_interval
	local damage_type = ability:GetAbilityDamageType()
	local radius = ability:GetSpecialValueFor("radius")
	local full_damage_radius = ability:GetSpecialValueFor("full_damage_radius")

	local missing_health = caster:GetHealthDeficit()
	local max_damage = max_missing_health_percent * missing_health / 100
	local min_damage = min_missing_health_percent * missing_health / 100

	local team = caster:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	-- DebugDrawCircle(origin, Vector(255,0,0), 1, radius, true, 0.2)
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(targets) do
		local distance = (unit:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
		local damage_modifier = 1 - (distance - full_damage_radius) / (radius - full_damage_radius)
		if damage_modifier > 1 then damage_modifier = 1 end
		local damage = min_damage + damage_modifier * (max_damage - min_damage)
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
	end

	local particle = ParticleManager:CreateParticle("particles/mokou/possessed_by_phoenix.vpcf", PATTACH_ABSORIGIN, target)
	-- ParticleManager:SetParticleControl(particle, 0, origin)
end