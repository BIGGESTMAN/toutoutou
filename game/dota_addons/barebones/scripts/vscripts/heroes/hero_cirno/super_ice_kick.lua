function superIceKickCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	-- Enable early cancel ability
	local main_ability_name	= ability:GetAbilityName()
	local sub_ability_name	= "super_ice_kick_end"
	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
	caster.ice_kick_target = target

	local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)
	local speed = ability:GetLevelSpecialValueFor("kick_speed", ability_level) * update_interval
	local arrival_distance = 65
	local arrived = false
	local spin_speed = 30

	local caster_location = caster:GetAbsOrigin()
	local target_point = target:GetAbsOrigin()
	local direction = (target_point - caster_location):Normalized()
	caster:SetForwardVector(direction)
	caster:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,0,-90), caster:GetForwardVector())) -- make cirno face the ground like a goof

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_super_ice_kick", {})

	Timers:CreateTimer(0, function()
		if caster:HasModifier("modifier_super_ice_kick") then
			caster:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,90,0), caster:GetForwardVector())) -- make cirno spin like a goof
			if not arrived then
				local caster_location = caster:GetAbsOrigin()
				local target_point = target:GetAbsOrigin()
				local direction = (target_point - caster_location):Normalized()
				local distance = (target_point - caster_location):Length2D()
				if distance > arrival_distance then
					-- Move caster
					caster:SetAbsOrigin(caster_location + direction * speed)
				else
					arrived = true
					FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), true)
					ability:ApplyDataDrivenModifier(caster, target, "modifier_super_ice_kick_stun", {})

					-- Deal initial damage
					local damage = ability:GetLevelSpecialValueFor("physical_damage_scaling", ability_level) * caster:GetAverageTrueAttackDamage() / 100
					local damage_type = DAMAGE_TYPE_PHYSICAL
					ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})
				end
			end
			return 0.03
		end
	end)
end

function dealDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target
	local caster_location = caster:GetAbsOrigin()

	local damage = ability:GetLevelSpecialValueFor("physical_damage_scaling", ability_level) * caster:GetAverageTrueAttackDamage() / 100
	local damage_type = DAMAGE_TYPE_PHYSICAL
	ApplyDamage({victim = target, attacker = caster, damage = damage, damage_type = damage_type})

	local number_of_shards = ability:GetLevelSpecialValueFor("shards", ability_level)
	local angle_increment = 360 / number_of_shards
	local prototype_target_point = (target:GetAbsOrigin() - caster_location):Normalized()
	for i=1,number_of_shards do
		local target_point = RotatePosition(Vector(0,0,0), QAngle(0,angle_increment * (i - 1),0), prototype_target_point) + caster_location

		local range = ability:GetLevelSpecialValueFor("shard_range", ability_level)
		local radius = ability:GetLevelSpecialValueFor("shard_radius", ability_level)
		local shard_damage = ability:GetLevelSpecialValueFor("shard_damage", ability_level)
		local shard_damage_type = DAMAGE_TYPE_MAGICAL
		local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)
		local speed = ability:GetLevelSpecialValueFor("shard_speed", ability_level) * 0.03

		local shard = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
		ability:ApplyDataDrivenModifier(caster, shard, "modifier_super_ice_kick_dummy", {})

		local particle = ParticleManager:CreateParticle("particles/cirno/ice_kick_shard.vpcf", PATTACH_ABSORIGIN_FOLLOW, shard)
		-- ParticleManager:SetParticleControlEnt(particle, 0, shard, PATTACH_POINT_FOLLOW, "attach_hitloc", shard:GetAbsOrigin(), true)
		-- ParticleManager:SetParticleControlEnt(particle, 4, shard, PATTACH_POINT_FOLLOW, "attach_hitloc", shard:GetAbsOrigin(), true)

		local shard_location = shard:GetAbsOrigin()
		local direction = (target_point - shard_location):Normalized()

		local distance_traveled = 0

		Timers:CreateTimer(0, function()
			if not shard:IsNull() then
				shard_location = shard:GetAbsOrigin()
				if distance_traveled < range then
					-- Move projectile
					shard:SetAbsOrigin(shard_location + direction * speed)
					distance_traveled = distance_traveled + speed
					-- ParticleManager:SetParticleControl(particle, 1, shard:GetAbsOrigin())

					-- Check for units hit
					local team = caster:GetTeamNumber()
					local origin = shard:GetAbsOrigin()
					local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
					local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
					local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
					local iOrder = FIND_CLOSEST
					-- DebugDrawCircle(origin, Vector(180,40,40), 0.1, radius / 5, true, 0.2)

					local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

					for k,unit in ipairs(targets) do
						if unit ~= target then
							ApplyDamage({victim = unit, attacker = caster, damage = shard_damage, damage_type = shard_damage_type})
							shard:RemoveSelf()
							break
						end
					end
					return 0.03
				else
					shard:RemoveSelf()
				end
			end
		end)
	end
end

function endKick(keys)
	local caster = keys.caster
	caster:RemoveModifierByName("modifier_super_ice_kick")
end

function kickEnded(keys)
	local caster = keys.caster
	local target = caster.ice_kick_target
	target:RemoveModifierByName("modifier_super_ice_kick_stun")
	caster:SetForwardVector(RotatePosition(Vector(0,0,0), QAngle(0,0,90), caster:GetForwardVector()))

	-- Disable cancel ability
	local main_ability_name	= keys.ability:GetAbilityName()
	local sub_ability_name	= "super_ice_kick_end"
	caster:SwapAbilities(main_ability_name, sub_ability_name, true, false)
end