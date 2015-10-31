function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local vanish_duration = ability:GetSpecialValueFor("vanish_duration")
	local duration = ability:GetSpecialValueFor("duration")
	local damage_dealt = ability:GetSpecialValueFor("damage_dealt")
	local damage_taken = ability:GetSpecialValueFor("damage_taken")
	local base_attack_time = ability:GetSpecialValueFor("base_attack_time")
	local damage_reduction = ability:GetSpecialValueFor("damage_reduction")
	local illusion_attack_angle = ability:GetSpecialValueFor("attacks_angle")
	local distance_between_units = ability:GetSpecialValueFor("distance_between_units")
	local illusion_count = ability:GetSpecialValueFor("illusions")
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local attack_range = ability:GetSpecialValueFor("illusion_range")

	local caster_location = caster:GetAbsOrigin()
	local caster_facing = caster:GetForwardVector()

	-- Make caster vanish
	caster:Stop()
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_four_of_a_kind_vanish", {})
	caster:AddNoDraw()

	-- Make caster reappear and create illusions
	Timers:CreateTimer(vanish_duration, function()
		caster:RemoveModifierByName("modifier_four_of_a_kind_vanish")
		caster:RemoveNoDraw()

		-- Make illusions
		local illusions = {}

		local player = caster:GetPlayerID()
		local unit_name = caster:GetUnitName()
		local outgoingDamage = ability:GetSpecialValueFor("damage_dealt") - 100
		local incomingDamage = ability:GetSpecialValueFor("damage_taken") - 100

		for i=1,illusion_count do
			local illusion = CreateUnitByName(unit_name, caster:GetAbsOrigin(), true, caster, nil, caster:GetTeamNumber())
			illusion:SetPlayerID(caster:GetPlayerID())
			
			-- Level up the unit to the casters level
			local casterLevel = caster:GetLevel()
			for i=1,casterLevel-1 do
				illusion:HeroLevelUp(false)
			end

			-- Set the skill points to 0 and learn the skills of the caster
			illusion:SetAbilityPoints(0)
			for abilitySlot=0,15 do
				local ability = caster:GetAbilityByIndex(abilitySlot)
				if ability ~= nil then 
					local abilityLevel = ability:GetLevel()
					local abilityName = ability:GetAbilityName()
					local illusionAbility = illusion:FindAbilityByName(abilityName)
					illusionAbility:SetLevel(abilityLevel)
				end
			end

			-- Recreate the items of the caster
			for itemSlot=0,5 do
				local item = caster:GetItemInSlot(itemSlot)
				if item ~= nil then
					local itemName = item:GetName()
					local newItem = CreateItem(itemName, illusion, illusion)
					illusion:AddItem(newItem)
				end
			end

			-- Set the unit as an illusion
			illusion:AddNewModifier(caster, ability, "modifier_illusion", {duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage})
			ability:ApplyDataDrivenModifier(caster, illusion, "modifier_four_of_a_kind_illusion", {})
			ability:ApplyDataDrivenModifier(caster, illusion, "modifier_four_of_a_kind_disarmed", {})
			illusion:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
			illusion:SetAcquisitionRange(0)
			illusion:MakeIllusion()

			table.insert(illusions, illusion)
		end

		-- Arrange units in line
		local units = illusions

		-- Randomize position of caster
		local caster_position_in_line = RandomInt(2, 3)
		table.insert(units, caster_position_in_line, caster)

		local right = RotatePosition(Vector(0,0,0), QAngle(0,-90,0), caster_facing)
		local initial_unit_location = caster_location + right * -1 * distance_between_units * illusion_count / 2
		FindClearSpaceForUnit(caster, initial_unit_location + right * distance_between_units * (caster_position_in_line - 1), true)
		caster:SetForwardVector(caster_facing)
		for i=1,#units do
			local unit_position_offset_from_caster = i - caster_position_in_line
			local offset = distance_between_units * unit_position_offset_from_caster
			local unit = units[i]
			if unit:IsIllusion() then
				Timers:CreateTimer(0, function()
					if not unit:IsNull() and unit:IsAlive() then
						-- Update position to stay with caster
						caster_location = caster:GetAbsOrigin()
						caster_facing = caster:GetForwardVector()
						right = RotatePosition(Vector(0,0,0), QAngle(0,-90,0), caster_facing)
						unit:SetAbsOrigin(caster_location + right * offset)

						-- Search for autoattack targets
						if not unit:IsAttacking() then
							unit:SetForwardVector(caster_facing)
							if unit:AttackReady() then -- Calculate angle
								local team = unit:GetTeamNumber()
								local origin = unit:GetAbsOrigin()
								local radius = attack_range
								local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
								local iType = DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_BASIC
								local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
								local iOrder = FIND_CLOSEST
								local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
								for k,possible_target in pairs(targets) do
									local direction = caster_facing
									local direction_towards_origin = (possible_target:GetAbsOrigin() - origin):Normalized()
									local angle = direction:Dot(direction_towards_origin)
									if angle >= (illusion_attack_angle / 360) then -- If unit is within attack angle
										unit:RemoveModifierByName("modifier_four_of_a_kind_disarmed")
										unit:SetForceAttackTarget(possible_target)
										Timers:CreateTimer(unit:GetAttackAnimationPoint(), function()
											ability:ApplyDataDrivenModifier(caster, unit, "modifier_four_of_a_kind_disarmed", {})
											unit:SetForceAttackTarget(nil)
										end)
										break
									end
								end
								-- Attack buildings if no units are in range
								if unit:HasModifier("modifier_four_of_a_kind_disarmed") then
									local team = unit:GetTeamNumber()
									local origin = unit:GetAbsOrigin()
									local radius = attack_range
									local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
									local iType = DOTA_UNIT_TARGET_BUILDING
									local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
									local iOrder = FIND_CLOSEST
									local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
									for k,possible_target in pairs(targets) do
										local direction = caster_facing
										local direction_towards_origin = (possible_target:GetAbsOrigin() - origin):Normalized()
										local angle = direction:Dot(direction_towards_origin)
										if angle >= (illusion_attack_angle / 360) then -- If unit is within attack angle
											unit:RemoveModifierByName("modifier_four_of_a_kind_disarmed")
											unit:SetForceAttackTarget(possible_target)
											Timers:CreateTimer(unit:GetAttackAnimationPoint(), function()
												ability:ApplyDataDrivenModifier(caster, unit, "modifier_four_of_a_kind_disarmed", {})
												unit:SetForceAttackTarget(nil)
											end)
											break
										end
									end
								end
							end
						end

						return update_interval
					end
				end)
			end
		end
	end)
end

function updateDamageReduction(keys)
	local caster = keys.caster
	local ability = keys.ability

	if caster:IsRealHero() then
		local illusion_search_radius = 20100

		local illusions = 0

		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local units = FindUnitsInRadius(team, origin, nil, illusion_search_radius, iTeam, iType, iFlag, iOrder, false)
		for k,unit in pairs(units) do
			if (unit:IsIllusion() and unit:GetPlayerID() == caster:GetPlayerID() and unit:IsAlive()) then
				illusions = illusions + 1
			end
		end

		if illusions > 0 then
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_four_of_a_kind_damage_reduction", {})
			caster:SetModifierStackCount("modifier_four_of_a_kind_damage_reduction", caster, illusions)
		else
			caster:RemoveModifierByName("modifier_four_of_a_kind_damage_reduction")
		end
	end
end