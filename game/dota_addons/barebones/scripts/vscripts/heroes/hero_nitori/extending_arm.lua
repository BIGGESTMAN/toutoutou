function extendingArmCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target_point = keys.target_points[1]

	local range = ability:GetLevelSpecialValueFor("range", ability_level)
	local speed = ability:GetLevelSpecialValueFor("travel_speed", ability_level) * 0.03
	local hand_radius = ability:GetLevelSpecialValueFor("hand_radius", ability_level)
	local damage_radius = ability:GetLevelSpecialValueFor("damage_radius", ability_level)
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
	local damage_type = ability:GetAbilityDamageType()
	local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)
	local arrival_distance = 25

	local arm = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, arm, "modifier_extending_arm_dummy", {})

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_shredder/shredder_timberchain_rope.vpcf", PATTACH_ABSORIGIN_FOLLOW, arm)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 4, arm, PATTACH_POINT_FOLLOW, "attach_hitloc", arm:GetAbsOrigin(), true)

	local arm_location = arm:GetAbsOrigin()
	local direction = (target_point - arm_location):Normalized()

	arm.unit_hit = nil
	arm.units_damaged = {}
	local distance_traveled = 0

	Timers:CreateTimer(0, function()
		arm_location = arm:GetAbsOrigin()
		if not arm.unit_hit then
			if distance_traveled < range then
				-- Move projectile
				arm:SetAbsOrigin(arm_location + direction * speed)
				distance_traveled = distance_traveled + speed
				ParticleManager:SetParticleControl(particle, 1, arm:GetAbsOrigin())

				-- Check for units hit
				local team = caster:GetTeamNumber()
				local origin = arm:GetAbsOrigin()
				local radius = hand_radius
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_TREE
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_CLOSEST
				DebugDrawCircle(origin, Vector(180,40,40), 1, radius, true, 0.5)

				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

				if #targets > 0 then
					arm.unit_hit = targets[1]
					arm.units_damaged[arm.unit_hit] = true
					ApplyDamage({victim = arm.unit_hit, attacker = caster, damage = damage, damage_type = damage_type})
					ability:ApplyDataDrivenModifier(caster, arm.unit_hit, "modifier_extending_arm_stun", {})
				else
					local trees = GridNav:GetAllTreesAroundPoint(arm:GetAbsOrigin(), hand_radius, false)
					if #trees > 0 then
						arm.unit_hit = trees[1]
					end
				end

				return 0.03
			else
				arm:RemoveSelf()
			end
		else
			arm:SetAbsOrigin(arm.unit_hit:GetAbsOrigin())
			local caster_location = caster:GetAbsOrigin()
			local distance = (arm.unit_hit:GetAbsOrigin() - caster_location):Length2D()
			direction = (arm.unit_hit:GetAbsOrigin() - caster_location):Normalized()
			if distance > arrival_distance then
				-- Move caster
				caster:SetAbsOrigin(caster_location + direction * speed)

				-- Check for units hit
				local team = caster:GetTeamNumber()
				local origin = caster_location
				local radius = damage_radius
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_ANY_ORDER

				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
				local damage_type = ability:GetAbilityDamageType()

				for k,unit in pairs(targets) do
					if not arm.units_damaged[unit] then
						ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
						arm.units_damaged[unit] = true
					end
				end

				return 0.03
			else
				FindClearSpaceForUnit(caster, arm.unit_hit:GetAbsOrigin(), false)
				arm:RemoveSelf()
			end
		end
	end)
end