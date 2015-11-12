function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage_type = ability:GetAbilityDamageType()
	local initial_damage = ability:GetSpecialValueFor("initial_damage")
	local min_damage_per_second = ability:GetSpecialValueFor("min_damage_per_second")
	local max_damage_per_second = ability:GetSpecialValueFor("max_damage_per_second")
	local max_damage_range = ability:GetSpecialValueFor("max_damage_range")
	local min_damage_range = ability:GetSpecialValueFor("min_damage_range")
	local removal_time = ability:GetSpecialValueFor("removal_time")
	local secondary_target_radius = ability:GetSpecialValueFor("secondary_target_radius")
	local damage_interval = ability:GetSpecialValueFor("damage_interval")
	local update_interval = ability:GetSpecialValueFor("update_interval")
	
	local particle_name = "particles/iku/dragons_gleaming_eyes/rope.vpcf"

	local elekiter = caster:HasModifier("modifier_elekiter_dragon_palace_active")
	if elekiter then
		max_damage_range = ability:GetSpecialValueFor("elekiter_max_damage_range")
		min_damage_range = ability:GetSpecialValueFor("elekiter_min_damage_range")
		removal_time = ability:GetSpecialValueFor("elekiter_removal_time")
		caster:RemoveModifierByName("modifier_elekiter_dragon_palace_active")
		particle_name = "particles/iku/dragons_gleaming_eyes/elekiter_rope.vpcf"
	end

	local secondary_target = nil

	local team = caster:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local radius = secondary_target_radius
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_CLOSEST
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	if #targets > 1 then secondary_target = targets[2] end

	ApplyDamage({victim = target, attacker = caster, damage = initial_damage, damage_type = damage_type})
	if secondary_target then
		ApplyDamage({victim = secondary_target, attacker = caster, damage = initial_damage, damage_type = damage_type})
		ability:ApplyDataDrivenModifier(caster, target, "modifier_dragons_gleaming_eyes_bound", {})
		ability:ApplyDataDrivenModifier(caster, secondary_target, "modifier_dragons_gleaming_eyes_bound", {})

		local particle = ParticleManager:CreateParticle(particle_name, PATTACH_POINT_FOLLOW, target)
		ParticleManager:SetParticleControlEnt(particle, 0, target, PATTACH_POINT_FOLLOW, "attach_hitloc", target:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 1, secondary_target, PATTACH_POINT_FOLLOW, "attach_hitloc", secondary_target:GetAbsOrigin(), true)

		local time_nearby = 0
		local time_since_damage = 0
		Timers:CreateTimer(0, function()
			if not target:IsNull() and target:HasModifier("modifier_dragons_gleaming_eyes_bound") and
			not secondary_target:IsNull() and secondary_target:HasModifier("modifier_dragons_gleaming_eyes_bound") then
				local distance = (target:GetAbsOrigin() - secondary_target:GetAbsOrigin()):Length2D()

				local in_range = distance > min_damage_range
				if elekiter then in_range = distance < min_damage_range end
				if not in_range then
					time_nearby = time_nearby + update_interval
					if time_nearby >= removal_time then
						target:RemoveModifierByName("modifier_dragons_gleaming_eyes_bound")
						secondary_target:RemoveModifierByName("modifier_dragons_gleaming_eyes_bound")
						ParticleManager:DestroyParticle(particle, false)
						return
					end
				else
					time_nearby = 0
				end

				time_since_damage = time_since_damage + update_interval
				if time_since_damage >= damage_interval then
					time_since_damage = time_since_damage - damage_interval
					local damage = min_damage_per_second
					if not elekiter then
						if distance > min_damage_range then
							if distance < max_damage_range then
								damage = damage + (max_damage_per_second - min_damage_per_second) * (distance - min_damage_range) / (max_damage_range - min_damage_range)
							else
								damage = max_damage_per_second
							end
						end
					else
						if distance < min_damage_range then
							if distance > max_damage_range then
								damage = damage + (max_damage_per_second - min_damage_per_second) * (1 - (distance - max_damage_range) / (min_damage_range - max_damage_range))
							else
								damage = max_damage_per_second
							end
						end
					end
					ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
					ApplyDamage({victim = secondary_target, attacker = caster, damage = damage, damage_type = damage_type})
				end
				return update_interval
			else
				if not target:IsNull() then target:RemoveModifierByName("modifier_dragons_gleaming_eyes_bound") end
				if not secondary_target:IsNull() then secondary_target:RemoveModifierByName("modifier_dragons_gleaming_eyes_bound") end
				ParticleManager:DestroyParticle(particle, false)
			end
		end)
	end
end