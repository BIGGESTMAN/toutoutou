function darkSideOfTheMoon(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local delay = ability:GetSpecialValueFor("detonation_delay")
	local radius = ability:GetSpecialValueFor("radius")

	local dummy_unit = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_unit, keys.dummy_modifier, {})
	ProjectileList:AddProjectile(dummy_unit)

	local particle = ParticleManager:CreateParticle(keys.particle_name, PATTACH_ABSORIGIN_FOLLOW, dummy_unit)

	local target_point = keys.target_points[1]
	local speed = ability:GetLevelSpecialValueFor("speed", ability_level) * 0.03

	Timers:CreateTimer(0, function()
		if not dummy_unit:IsNull() then
			local dummy_location = dummy_unit:GetAbsOrigin()
			local distance = (target_point - dummy_location):Length2D()
			local direction = (target_point - dummy_location):Normalized()
			if distance > 25 then
				if not dummy_unit.frozen then
					dummy_unit:SetAbsOrigin(dummy_location + direction * speed)
				end
				return 0.03
			else
				dummy_unit:SetAbsOrigin(target_point)
				ProjectileList:RemoveProjectile(dummy_unit)

				-- DebugDrawCircle(target_point, Vector(40,40,180), 1, radius, true, delay + 0.5)
				Timers:CreateTimer(0.06, function() -- wait a bit so particle isn't offset
					local aoe_particle = ParticleManager:CreateParticle("particles/rumia/dark_side_aoe.vpcf", PATTACH_ABSORIGIN, dummy_unit)
					ParticleManager:SetParticleControl(aoe_particle, 1, Vector(radius,0,0))
				end)

				Timers:CreateTimer(delay, function()
					local team = caster:GetTeamNumber()
					local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
					local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
					local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
					local iOrder = FIND_ANY_ORDER

					local targets = FindUnitsInRadius(team, target_point, nil, radius, iTeam, iType, iFlag, iOrder, false)
					local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
					local damage_multiplier = ability:GetLevelSpecialValueFor("damage_multiplier", ability_level)
					local damage_type = ability:GetAbilityDamageType()

					for k,unit in pairs(targets) do
						local final_damage = damage
						if not caster:CanEntityBeSeenByMyTeam(unit) then final_damage = final_damage * damage_multiplier end
						ApplyDamage({ victim = unit, attacker = caster, damage = final_damage, damage_type = damage_type})
					end

					local explosion_particle = ParticleManager:CreateParticle("particles/rumia/dark_side_explosion.vpcf", PATTACH_ABSORIGIN_FOLLOW, dummy_unit)
					ParticleManager:SetParticleControl(explosion_particle, 1, Vector(1,radius,1))
					ParticleManager:SetParticleControlEnt(explosion_particle, 0, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)

					-- time out particle dummy after a while
					Timers:CreateTimer(2, function()
						dummy_unit:RemoveSelf()
					end)
					ParticleManager:DestroyParticle(particle, false)
				end)
			end
		end
	end)
end