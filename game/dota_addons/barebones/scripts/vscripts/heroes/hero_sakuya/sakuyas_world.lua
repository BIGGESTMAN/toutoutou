function spellCast(keys)
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local target_point = keys.target_points[1]
	local ability = keys.ability

	local enhanced_range_bonus = caster:FindAbilityByName("checkmaid"):GetSpecialValueFor("enhanced_dagger_bonus_range")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")
	local damage_type = ability:GetAbilityDamageType()
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local speed = ability:GetSpecialValueFor("dagger_speed") * update_interval

	local target_direction = (target_point - caster_location):Normalized()
	if target_point == caster_location then target_direction = caster:GetForwardVector() end
	local cast_range = ability:GetSpecialValueFor("range")
	local distance = (target_point - caster_location):Length2D()
	if distance > cast_range then
		target_point = caster_location + target_direction * cast_range
	end

	FindClearSpaceForUnit(caster, target_point, false)
	ProjectileManager:ProjectileDodge(caster)

	local start_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_phantom_strike_start.vpcf", PATTACH_POINT, caster)
	ParticleManager:SetParticleControl(start_particle, 0, caster_location)
	local end_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_phantom_strike_end.vpcf", PATTACH_POINT, caster)
	ParticleManager:SetParticleControl(start_particle, 0, target_point)

	local daggers = {}
	for i=1,2 do
		local dagger = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
		ProjectileList:AddProjectile(dagger)
		table.insert(daggers, dagger)
	end
	daggers[1]:SetForwardVector(target_direction)
	daggers[1]:SetAbsOrigin(caster_location)
	daggers[2]:SetForwardVector(target_direction * -1)
	daggers[2]:SetAbsOrigin(target_point)

	for k,dagger in pairs(daggers) do
		local range = ability:GetSpecialValueFor("dagger_range")
		local enhanced = false
		local units_hit = {}
		local distance_traveled = 0

		local direction = dagger:GetForwardVector()
		direction.z = 0

		local particle = ParticleManager:CreateParticle("particles/sakuya/killing_doll_dagger.vpcf", PATTACH_ABSORIGIN_FOLLOW, dagger)
		ParticleManager:SetParticleControl(particle, 1, dagger:GetAbsOrigin() + direction)

		Timers:CreateTimer(0, function()
			if not dagger:IsNull() then
				-- Check for Checkmaid on-cooldown bonus
				if not dagger.enhanced then
					local checkmaid_ability = caster:FindAbilityByName("checkmaid")
					if not checkmaid_ability:IsCooldownReady() then
						enhanced = true
						range = range + enhanced_range_bonus
					end
				end

				if distance_traveled < range then
					if not dagger.frozen then
						-- Move projectile
						dagger:SetAbsOrigin(dagger:GetAbsOrigin() + direction * speed)
						distance_traveled = distance_traveled + speed

						-- Check for units hit
						local team = caster:GetTeamNumber()
						local origin = dagger:GetAbsOrigin()
						local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
						local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
						local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
						local iOrder = FIND_CLOSEST
						-- DebugDrawCircle(origin, Vector(180,40,40), 0.1, radius, true, 0.2)

						local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

						if not enhanced then
							if #targets > 0 then
								daggerHit(caster, ability, targets[1], damage, damage_type, cooldown_increase_max)
								dagger:RemoveSelf()
							end
						else
							for k,unit in pairs(targets) do
								if not units_hit[unit] then
									daggerHit(caster, ability, unit, damage, damage_type, cooldown_increase_max)
									units_hit[unit] = true
								end
							end
						end
					end
					return update_interval
				else
					dagger:RemoveSelf()
				end
			end
		end)
	end
end

function daggerHit(caster, ability, unit, damage, damage_type, cooldown_increase_max)
	ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})

	local hit_particle = ParticleManager:CreateParticle("particles/sakuya/killing_doll_dagger_explosion.vpcf", PATTACH_POINT, unit)
	ParticleManager:SetParticleControlEnt(hit_particle, 0, unit, PATTACH_POINT, "attach_hitloc", unit:GetAbsOrigin(), true)
end