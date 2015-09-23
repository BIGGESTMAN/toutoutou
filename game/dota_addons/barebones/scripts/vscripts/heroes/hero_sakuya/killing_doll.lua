function spellCast(keys)
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local ability = keys.ability

	local cooldown_increase_max = ability:GetSpecialValueFor("cooldown_increase_max")

	local number_of_knives = ability:GetSpecialValueFor("knives")
	local cone_width = ability:GetSpecialValueFor("cone_width_degrees")
	local angle_increment = cone_width / (number_of_knives - 1)
	local initial_angle = cone_width / -2
	local prototype_target_point = (keys.target_points[1] - caster_location):Normalized()
	-- DebugDrawCircle(caster_location, Vector(180,40,40), 0.1, 150, true, 0.5)
	-- DebugDrawCircle(caster_location, Vector(255,40,40), 0.1, 350, true, 0.5)

	-- Trigger increased cooldown from previous hits
	-- if caster:HasModifier("modifier_killing_doll_cooldown_increase") then
	-- 	local cooldown_increase = caster:GetModifierStackCount("modifier_killing_doll_cooldown_increase", caster)
	-- 	ability:StartCooldown(ability:GetCooldown(ability:GetLevel() - 1) + cooldown_increase)
	-- end

	for i=1,number_of_knives do
		local angle = initial_angle + angle_increment * (i - 1)
		local target_point = RotatePosition(Vector(0,0,0), QAngle(0,angle,0), prototype_target_point) + caster_location

		local range = ability:GetSpecialValueFor("range")
		local radius = ability:GetSpecialValueFor("radius")
		local knife_damage = ability:GetSpecialValueFor("damage")
		local knife_damage_type = ability:GetAbilityDamageType()
		local update_interval = ability:GetSpecialValueFor("update_interval")
		local speed = ability:GetSpecialValueFor("travel_speed") * update_interval

		local knife = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
		ability:ApplyDataDrivenModifier(caster, knife, "modifier_killing_doll_dummy", {})

		local particle = ParticleManager:CreateParticle("particles/sakuya/killing_doll_dagger.vpcf", PATTACH_ABSORIGIN_FOLLOW, knife)
		ParticleManager:SetParticleControl(particle, 1, target_point)

		-- local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_stifling_dagger.vpcf", PATTACH_ABSORIGIN_FOLLOW, knife)
		-- local particle = ParticleManager:CreateParticle("particles/sakuya/killing_doll_dagger_alt.vpcf", PATTACH_ABSORIGIN_FOLLOW, knife)
		-- ParticleManager:SetParticleControlEnt(particle, 1, knife, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", knife:GetAbsOrigin(), true)
		-- ParticleManager:SetParticleControl(particle, 2, Vector(speed / update_interval,0,0))

		local knife_location = knife:GetAbsOrigin()
		local direction = (target_point - knife_location):Normalized()
		direction.z = 0

		local distance_traveled = 0

		Timers:CreateTimer(0, function()
			if not knife:IsNull() then
				knife_location = knife:GetAbsOrigin()
				if distance_traveled < range then
					-- Move projectile
					knife:SetAbsOrigin(knife_location + direction * speed)
					distance_traveled = distance_traveled + speed

					-- Check for units hit
					local team = caster:GetTeamNumber()
					local origin = knife:GetAbsOrigin()
					local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
					local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
					local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
					local iOrder = FIND_CLOSEST
					-- DebugDrawCircle(origin, Vector(180,40,40), 0.1, radius, true, 0.2)

					local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

					if #targets > 0 then
						local unit = targets[1]
						ApplyDamage({victim = unit, attacker = caster, damage = knife_damage, damage_type = knife_damage_type})
						ability:ApplyDataDrivenModifier(caster, caster, "modifier_killing_doll_cooldown_increase", {})
						if caster:GetModifierStackCount("modifier_killing_doll_cooldown_increase", caster) < cooldown_increase_max then
							caster:FindModifierByName("modifier_killing_doll_cooldown_increase"):IncrementStackCount()
						end
						knife:RemoveSelf()

						local hit_particle = ParticleManager:CreateParticle("particles/sakuya/killing_doll_dagger_explosion.vpcf", PATTACH_POINT, unit)
						ParticleManager:SetParticleControlEnt(hit_particle, 0, unit, PATTACH_POINT, "attach_hitloc", unit:GetAbsOrigin(), true)
					end
					return update_interval
				else
					knife:RemoveSelf()
				end
			end
		end)
	end
end