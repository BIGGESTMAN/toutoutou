function spellCast(keys)
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local ability = keys.ability

	local enhanced_range_bonus = caster:FindAbilityByName("checkmaid"):GetSpecialValueFor("enhanced_dagger_bonus_range")
	local radius = ability:GetSpecialValueFor("radius")
	local knife_damage = ability:GetSpecialValueFor("damage")
	local knife_damage_type = ability:GetAbilityDamageType()
	local cooldown_increase_max = ability:GetSpecialValueFor("cooldown_increase_max")
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local speed = ability:GetSpecialValueFor("travel_speed") * update_interval

	local number_of_knives = ability:GetSpecialValueFor("knives")
	local cone_width = ability:GetSpecialValueFor("cone_width_degrees")
	local angle_increment = cone_width / (number_of_knives - 1)
	local initial_angle = cone_width / -2
	local prototype_target_point = (keys.target_points[1] - caster_location):Normalized()

	-- Trigger increased cooldown from previous hits
	if caster:HasModifier("modifier_killing_doll_cooldown_increase") then
		local cooldown_increase = caster:GetModifierStackCount("modifier_killing_doll_cooldown_increase", caster)
		ability:StartCooldown(ability:GetCooldown(ability:GetLevel() - 1) + cooldown_increase)
	end

	for i=1,number_of_knives do
		local angle = initial_angle + angle_increment * (i - 1)
		local target_point = RotatePosition(Vector(0,0,0), QAngle(0,angle,0), prototype_target_point) + caster_location

		local range = ability:GetSpecialValueFor("range")
		local enhanced = false
		local units_hit = {}

		local knife = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
		ability:ApplyDataDrivenModifier(caster, knife, "modifier_killing_doll_dummy", {})
		ProjectileList:AddProjectile(knife)

		local particle = ParticleManager:CreateParticle("particles/sakuya/killing_doll_dagger.vpcf", PATTACH_ABSORIGIN_FOLLOW, knife)
		ParticleManager:SetParticleControl(particle, 1, target_point)

		-- Other particles for debugging
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
				-- Check for Checkmaid on-cooldown bonus
				if not knife.enhanced then
					local checkmaid_ability = caster:FindAbilityByName("checkmaid")
					if not checkmaid_ability:IsCooldownReady() then
						enhanced = true
						range = range + enhanced_range_bonus
					end
				end

				knife_location = knife:GetAbsOrigin()
				if distance_traveled < range then
					if not knife.frozen then
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

						if not enhanced then
							if #targets > 0 then
								knifeHit(caster, ability, targets[1], knife_damage, knife_damage_type, cooldown_increase_max)
								knife:RemoveSelf()
							end
						else
							for k,unit in pairs(targets) do
								if not units_hit[unit] then
									knifeHit(caster, ability, unit, knife_damage, knife_damage_type, cooldown_increase_max)
									units_hit[unit] = true
								end
							end
						end
					end
					return update_interval
				else
					knife:RemoveSelf()
				end
			end
		end)
	end
end

function knifeHit(caster, ability, unit, damage, damage_type, cooldown_increase_max)
	ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_killing_doll_cooldown_increase", {})
	if caster:GetModifierStackCount("modifier_killing_doll_cooldown_increase", caster) < cooldown_increase_max then
		caster:FindModifierByName("modifier_killing_doll_cooldown_increase"):IncrementStackCount()
	end

	local hit_particle = ParticleManager:CreateParticle("particles/sakuya/killing_doll_dagger_explosion.vpcf", PATTACH_POINT, unit)
	ParticleManager:SetParticleControlEnt(hit_particle, 0, unit, PATTACH_POINT, "attach_hitloc", unit:GetAbsOrigin(), true)
end