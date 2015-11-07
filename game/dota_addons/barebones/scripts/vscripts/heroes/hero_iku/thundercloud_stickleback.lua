function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage = ability:GetSpecialValueFor("initial_damage")
	local damage_type = ability:GetAbilityDamageType()

	ability:ApplyDataDrivenModifier(caster, target, "modifier_thundercloud_stickleback", {})
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
	end
end

function explode(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("explosion_damage")
	local damage_type = ability:GetAbilityDamageType()
	local knockback_range = ability:GetSpecialValueFor("knockback_range")
	local knockback_duration = ability:GetSpecialValueFor("knockback_duration")
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local speed = knockback_range / knockback_duration * update_interval

	local team = caster:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	DebugDrawCircle(origin, Vector(0,0,255), 1, radius, true, 0.75)

	for k,unit in pairs(targets) do
		if unit ~= target then
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_thundercloud_stickleback_slow", {})

			local direction = (unit:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()
			local target_range = knockback_range
			local distance_traveled = 0

			ability:ApplyDataDrivenModifier(caster, unit, "modifier_thundercloud_stickleback_knockback", {})

			Timers:CreateTimer(0, function()
				if not unit:IsNull() and unit:IsAlive() then
					if distance_traveled < knockback_range then
						-- Move unit -- includes a distance check to prevent overshooting
						local distance = target_range - distance_traveled
						if speed < distance then
							unit:SetAbsOrigin(unit:GetAbsOrigin() + direction * speed)
						else
							unit:SetAbsOrigin(unit:GetAbsOrigin() + direction * distance)
						end
						distance_traveled = distance_traveled + speed
						return update_interval
					else
						FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
						unit:RemoveModifierByName("modifier_thundercloud_stickleback_knockback")
					end
				end
			end)
		end
	end
end