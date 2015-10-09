function SpellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("damage_percent") / 100
	local damage_type = DAMAGE_TYPE_PHYSICAL
	local persona_damage_type = "physical"
	ApplyCustomDamage(target, caster, damage, damage_type, persona_damage_type)

	local self_damage = caster:GetMaxHealth() * ability:GetSpecialValueFor("health_cost_percent") / 100
	caster:SetHealth(caster:GetHealth() - self_damage)

	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local radius = ability:GetSpecialValueFor("radius")
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	-- DebugDrawCircle(origin, Vector(180,40,40), 0.1, radius, true, 0.2)

	local aoe_damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("aoe_damage_percent") / 100
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		ApplyCustomDamage(unit, caster, aoe_damage, damage_type, persona_damage_type)
	end

	ParticleManager:CreateParticle("particles/units/heroes/hero_bristleback/bristleback_quill_spray_quills.vpcf", PATTACH_ABSORIGIN, caster)
end