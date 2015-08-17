function extendingArmCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target_point = keys.target_points[1]

	local range = ability:GetLevelSpecialValueFor("range", ability_level)
	local speed = ability:GetLevelSpecialValueFor("travel_speed", ability_level)
	local hand_radius = ability:GetLevelSpecialValueFor("hand_radius", ability_level)
	local damage_radius = ability:GetLevelSpecialValueFor("damage_radius", ability_level)
	local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)
	local dummy_speed = speed * 0.03
	local arrival_distance = 25

	local arm = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, arm, "modifier_extending_arm_dummy", {})

	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_shredder/shredder_timberchain.vpcf", PATTACH_ABSORIGIN_FOLLOW, arm)
	ParticleManager:SetParticleControl(particle, 0, caster:GetAbsOrigin())

	local arm_location = arm:GetAbsOrigin()
	local direction = (target_point - arm_location):Normalized()

	arm.unit_hit = nil
	local distance_traveled = 0

	Timers:CreateTimer(0, function()
		arm_location = arm:GetAbsOrigin()
		if not arm.unit_hit then
			if distance_traveled < range then
				-- Move projectile
				arm:SetAbsOrigin(arm_location + direction * dummy_speed)
				distance_traveled = distance_traveled + dummy_speed
				ParticleManager:SetParticleControl(particle, 1, arm:GetAbsOrigin())

				-- Check for units hit
				local team = caster:GetTeamNumber()
				local origin = arm_location
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_CLOSEST
				local radius = ability:GetLevelSpecialValueFor("hand_radius", ability_level)
				DebugDrawCircle(origin, Vector(180,40,40), 1, radius, true, 0.5)

				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
				local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
				local damage_type = ability:GetAbilityDamageType()

				if #targets > 0 then
					arm.unit_hit = targets[1]
				end
				return 0.03
			else
				arm:RemoveSelf()
			end
		else
			local distance = (arm.unit_hit:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
			local anchor_direction = anchor:GetForwardVector()
		end
	end)
end