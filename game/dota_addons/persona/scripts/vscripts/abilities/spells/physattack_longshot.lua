function SpellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local range = ability:GetSpecialValueFor("range")
	local radius = ability:GetSpecialValueFor("radius")
	local min_damage_percent = ability:GetSpecialValueFor("min_damage_percent")
	local max_damage_percent = ability:GetSpecialValueFor("max_damage_percent")
	local max_damage_distance = ability:GetSpecialValueFor("max_damage_distance")
	local damage_type = DAMAGE_TYPE_PHYSICAL
	local persona_damage_type = "physical"
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local speed = ability:GetSpecialValueFor("speed") * update_interval

	local self_damage = caster:GetMaxHealth() * ability:GetSpecialValueFor("health_cost_percent") / 100
	caster:SetHealth(caster:GetHealth() - self_damage)

	local spear = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, spear, "modifier_longshot_dummy", {})

	local particle = ParticleManager:CreateParticle("particles/spells/physattack_longshot.vpcf", PATTACH_ABSORIGIN_FOLLOW, spear)
	-- ParticleManager:SetParticleControl(particle, 1, target_point)

	-- Other particles for debugging
	-- local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf", PATTACH_ABSORIGIN_FOLLOW, spear)
	-- local particle = ParticleManager:CreateParticle("particles/sakuya/killing_doll_dagger_alt.vpcf", PATTACH_ABSORIGIN_FOLLOW, spear)
	ParticleManager:SetParticleControlEnt(particle, 0, spear, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", spear:GetAbsOrigin(), true)
	-- ParticleManager:SetParticleControl(particle, 2, Vector(speed / update_interval,0,0))

	local spear_location = spear:GetAbsOrigin()
	local direction = (target_point - spear_location):Normalized()
	direction.z = 0
	spear:SetForwardVector(direction)

	local distance_traveled = 0

	Timers:CreateTimer(0, function()
		if not spear:IsNull() then
			spear_location = spear:GetAbsOrigin()
			if distance_traveled < range then
				-- Move projectile
				spear:SetAbsOrigin(spear_location + direction * speed)
				distance_traveled = distance_traveled + speed

				-- Check for units hit
				local team = caster:GetTeamNumber()
				local origin = spear:GetAbsOrigin()
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_CLOSEST
				-- DebugDrawCircle(origin, Vector(180,40,40), 0.1, radius, true, 0.2)

				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

				if #targets > 0 then
					local max_damage_factor = distance_traveled / max_damage_distance
					if max_damage_factor > 1 then max_damage_factor = 1 end
					local damage_percent = min_damage_percent + (max_damage_percent - min_damage_percent) * max_damage_factor
					local damage = caster:GetAverageTrueAttackDamage() * damage_percent / 100
					ApplyCustomDamage(targets[1], caster, damage, damage_type, persona_damage_type)
					spear:RemoveSelf()
				else
					return update_interval
				end
			else
				spear:RemoveSelf()
			end
		end
	end)
end