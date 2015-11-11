function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local damage = ability:GetSpecialValueFor("initial_damage")
	local damage_type = ability:GetAbilityDamageType()

	if not caster:HasModifier("modifier_elekiter_dragon_palace_active") then
		ability:ApplyDataDrivenModifier(caster, target, "modifier_thundercloud_stickleback", {})
	else
		ability:ApplyDataDrivenModifier(caster, target, "modifier_thundercloud_stickleback_elekiter", {})
		caster:RemoveModifierByName("modifier_elekiter_dragon_palace_active")
	end
	if target:GetTeamNumber() ~= caster:GetTeamNumber() then
		ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
	end
end

function normalExplode(keys)
	explode(keys.caster, keys.ability, keys.target, false)
end

function elekiterExplode(keys)
	explode(keys.caster, keys.ability, keys.target, true)
end

function explode(caster, ability, target, elekiter)
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
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_thundercloud_stickleback_slow", {})

		if unit ~= target then
			local direction = (unit:GetAbsOrigin() - target:GetAbsOrigin()):Normalized()
			local target_range = knockback_range
			if elekiter then
				direction = direction * -1
				target_range = (unit:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
			end
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
						FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), elekiter)
						unit:RemoveModifierByName("modifier_thundercloud_stickleback_knockback")
					end
				end
			end)
		end
	end
end