function spellCast(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	if caster ~= target then
		caster.checkmaid_target = target
		local target_location = target:GetAbsOrigin()

		local dagger_count = ability:GetSpecialValueFor("daggers")
		local radius = ability:GetSpecialValueFor("radius")

		ability:ApplyDataDrivenModifier(caster, target, "modifier_checkmaid", {})
		target.checkmaid_daggers = {}

		local angle_increment = 360 / dagger_count
		local prototype_target_point = (target_location - caster:GetAbsOrigin()):Normalized()
		for i=1, dagger_count do
			local dagger = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
			ability:ApplyDataDrivenModifier(caster, dagger, "modifier_checkmaid_dummy", {})
			table.insert(target.checkmaid_daggers, dagger)

			local target_point = RotatePosition(Vector(0,0,0), QAngle(0,angle_increment * (i - 1),0), prototype_target_point) * ability:GetSpecialValueFor("radius") + target_location
			dagger:SetAbsOrigin(target_point)
			local direction = (target_location - target_point):Normalized()
			dagger:SetForwardVector(direction)

			local particle = ParticleManager:CreateParticle("particles/sakuya/killing_doll_dagger.vpcf", PATTACH_ABSORIGIN_FOLLOW, dagger)
			ParticleManager:SetParticleControl(particle, 1, target_location)
		end

		-- Enable end early ability
		local main_ability_name	= ability:GetAbilityName()
		local sub_ability_name	= "checkmaid_end"
		caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
	else
		ability:RefundManaCost()
		ability:EndCooldown()
	end
end

function durationEnded(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local dagger_distance = ability:GetSpecialValueFor("dagger_flight_range")
	local dagger_radius = ability:GetSpecialValueFor("dagger_radius")
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local dagger_speed = ability:GetSpecialValueFor("dagger_speed") * update_interval
	local damage = ability:GetSpecialValueFor("damage")
	local damage_type = ability:GetAbilityDamageType()

	caster.checkmaid_target = nil

	local daggers = target.checkmaid_daggers
	target.checkmaid_daggers = nil

	for k,dagger in pairs(daggers) do
		local distance_traveled = 0
		local units_hit = {}
		Timers:CreateTimer(0, function()
			if not dagger:IsNull() then
				dagger_location = dagger:GetAbsOrigin()
				if distance_traveled < dagger_distance then
					-- Move dagger
					dagger:SetAbsOrigin(dagger_location + dagger:GetForwardVector() * dagger_speed)
					distance_traveled = distance_traveled + dagger_speed

					-- Check for units hit
					local team = caster:GetTeamNumber()
					local origin = dagger_location
					local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
					local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
					local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
					local iOrder = FIND_ANY_ORDER
					-- DebugDrawCircle(origin, Vector(180,40,40), 0.1, dagger_radius, true, 0.2)

					local targets = FindUnitsInRadius(team, origin, nil, dagger_radius, iTeam, iType, iFlag, iOrder, false)
					for k,unit in pairs(targets) do
						if not units_hit[unit] then
							ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
							units_hit[unit] = true

							local hit_particle = ParticleManager:CreateParticle("particles/sakuya/killing_doll_dagger_explosion.vpcf", PATTACH_POINT, unit)
							ParticleManager:SetParticleControlEnt(hit_particle, 0, unit, PATTACH_POINT, "attach_hitloc", unit:GetAbsOrigin(), true)
						end
					end
					return update_interval
				else
					dagger:RemoveSelf()
				end
			end
		end)
	end

	-- Disable cannon shot ability
	local main_ability_name	= "checkmaid"
	local sub_ability_name	= "checkmaid_end"
	caster:SwapAbilities(main_ability_name, sub_ability_name, true, false)
end

function onUpgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:FindAbilityByName("checkmaid_end"):SetLevel(ability:GetLevel())
	caster.checkmaid_target = nil
end

function endEarly(keys)
	local caster = keys.caster
	local target = caster.checkmaid_target
	if not target:IsNull() then -- Not sure this check is necessary, but just to be safe
		target:RemoveModifierByName("modifier_checkmaid")
	end
end