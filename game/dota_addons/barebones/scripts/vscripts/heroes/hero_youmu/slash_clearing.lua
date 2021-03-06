require "heroes/hero_youmu/eternal_truth"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local illusion_search_radius = 800
	local target_location = target:GetAbsOrigin()
	local direction_from_cast = (target_location - caster:GetAbsOrigin()):Normalized()
	direction_from_cast.z = 0
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local charge_delay = ability:GetSpecialValueFor("charge_delay")
	local charge_distance = ability:GetSpecialValueFor("charge_distance")
	local charge_speed = ability:GetSpecialValueFor("charge_speed") * update_interval
	local damage = caster:GetAverageTrueAttackDamage() * ability:GetSpecialValueFor("illusion_damage_percent") / 100
	local damage_type = ability:GetAbilityDamageType()
	local hit_distance = 50

	-- Stun target
	ability:ApplyDataDrivenModifier(caster, target, "modifier_slash_clearing_stun", {})

	-- Find existing illusions
	local units = {}
	local nearby_units = Entities:FindAllInSphere(caster:GetAbsOrigin(), illusion_search_radius)
	for k,unit in pairs(nearby_units) do
		-- if unit.GetMainControllingPlayer and unit:GetMainControllingPlayer() == caster:GetMainControllingPlayer() and unit:GetName() == caster:GetName() then
		if (unit.IsIllusion and unit:IsIllusion() and unit:GetPlayerID() == caster:GetPlayerID() and unit:IsAlive()) or unit == caster then
			table.insert(units, unit)
		end
	end

	-- Make caster and illusions vanish
	for k,unit in pairs(units) do
		unit:Stop()
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_slash_clearing_vanish", {})
		unit:AddNoDraw()
	end

	-- Vanish particle
	ParticleManager:CreateParticle("particles/youmu/slash_clearing_vanish.vpcf", PATTACH_ABSORIGIN, caster)

	Timers:CreateTimer(ability:GetSpecialValueFor("vanish_duration"), function()
		-- Start delay particle
		ParticleManager:CreateParticle("particles/youmu/slash_clearing_delay.vpcf", PATTACH_ABSORIGIN, target)

		for k,unit in pairs(units) do
			unit:RemoveModifierByName("modifier_slash_clearing_vanish")
			unit:RemoveNoDraw()
		end

		-- Make illusions
		local player = caster:GetPlayerID()
		local unit_name = caster:GetUnitName()
		local outgoingDamage = 0
		local incomingDamage = ability:GetSpecialValueFor("illusion_damage_taken") - 100

		for i=1,ability:GetSpecialValueFor("illusions") do
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
			illusion:AddNewModifier(caster, ability, "modifier_illusion", {outgoing_damage = outgoingDamage, incoming_damage = incomingDamage})
			illusion:MakeIllusion()
			illusion.slash_clearing_illusion = true

			table.insert(units, illusion)
		end

		-- Arrange units around target
		local angle_increment = 360 / #units
		local prototype_target_point = direction_from_cast
		target_location = target:GetAbsOrigin()
		for k,unit in pairs(units) do
			local target_point = RotatePosition(Vector(0,0,0), QAngle(0,angle_increment * (k - 1),0), prototype_target_point) * ability:GetSpecialValueFor("radius") + target_location

			unit:SetAbsOrigin(target_point)
			if unit == caster then
				unit:Stop()
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), true)
			end
			
			local direction = (target_location - unit:GetAbsOrigin()):Normalized()
			unit:SetForwardVector(direction)

			-- Reappearing particle
			ParticleManager:CreateParticle("particles/youmu/slash_clearing_reappear.vpcf", PATTACH_ABSORIGIN, unit)

			-- Make illusion charge
			if unit:IsIllusion() then
				ability:ApplyDataDrivenModifier(caster, unit, "modifier_slash_clearing_illusion", {})
				local distance_traveled = 0
				local has_hit_target = false
				Timers:CreateTimer(charge_delay, function()
					if not unit:IsNull() then
						if not target:IsNull() and target:IsAlive() then
							unit_location = unit:GetAbsOrigin()
							target_location = target:GetAbsOrigin()
							if distance_traveled < charge_distance or not has_hit_target then
								-- Move illusion
								if not has_hit_target and not target:IsNull() then
									direction = (target_location - unit_location):Normalized()
									unit:SetForwardVector(direction)
								else
									has_hit_target = true
									distance_traveled = distance_traveled + charge_speed
								end
								unit:SetAbsOrigin(unit_location + direction * charge_speed)

								-- Check for hit
								if not has_hit_target and not target:IsNull() then
									local distance_to_target = (target:GetAbsOrigin() - unit:GetAbsOrigin()):Length2D()
									if distance_to_target < hit_distance then
										ApplyDamage({victim = target, attacker = unit, damage = damage, damage_type = damage_type})
										echoDamage(caster, damage, damage_type)
										has_hit_target = true
									end
								end
								return update_interval
							else
								-- Expire at end of charge distance if illusion was created by this ability
								endDash(unit)
							end
						else
							endDash(unit)
						end
					end
				end)
			end
		end
	end)
end

function endDash(illusion)
	if illusion.slash_clearing_illusion then
		illusion:ForceKill(false)
	else
		illusion:RemoveModifierByName("modifier_slash_clearing_illusion")
		FindClearSpaceForUnit(illusion, illusion:GetAbsOrigin(), false)
	end
end