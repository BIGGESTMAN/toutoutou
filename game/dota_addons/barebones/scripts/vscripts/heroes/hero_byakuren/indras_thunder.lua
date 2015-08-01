function indrasThunderCast(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Spend a charge
	local charge_modifier = caster:FindModifierByName("modifier_vajrapanis_charges")
	if charge_modifier:GetStackCount() > 1 then
		charge_modifier:DecrementStackCount()
	else
		charge_modifier:Destroy()
	end

	--------------------------------------------- Dummy projectile ----------------------------------
	if not caster.bead_dummy_projectiles then
		caster.bead_dummy_projectiles = {}
	end

	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)

	local dummy_projectile = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	caster.bead_dummy_projectiles[dummy_projectile] = true
	ability:ApplyDataDrivenModifier(caster, dummy_projectile, keys.projectile_modifier, {})

	local target_point = target:GetAbsOrigin()

	local dummy_speed = speed * 0.03
	local arrival_distance = 25

	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

	Timers:CreateTimer(0, function()
		if not target:IsNull() then target_point = target:GetAbsOrigin() end
		local dummy_location = dummy_projectile:GetAbsOrigin()
		local distance = (target_point - dummy_location):Length2D()
		local direction = (target_point - dummy_location):Normalized()
		if distance > arrival_distance then
			-- Move projectile
			dummy_projectile:SetAbsOrigin(dummy_location + direction * dummy_speed)
			return 0.03
		else
			dummy_projectile:SetAbsOrigin(target_point)
			-- Trigger delayed bead activation
			Timers:CreateTimer(ability:GetLevelSpecialValueFor("delay", ability_level),function()
				local team = caster:GetTeamNumber()
				local origin = target_point
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_ANY_ORDER
				DebugDrawCircle(origin, Vector(180,180,40), 1, radius, true, 0.5)

				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
				local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
				local damage_type = ability:GetAbilityDamageType()

				local pull_duration = ability:GetLevelSpecialValueFor("pull_duration", ability_level)
				local elapsed_time = 0
				local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)
				local angle_rotated = 90

				for k,unit in pairs(targets) do
					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_pulled", {})
				end

				-- Spin/vacuum hit units
				Timers:CreateTimer(0, function()
					if elapsed_time < pull_duration then
						for k,unit in pairs(targets) do
							unit:SetAbsOrigin(RotatePosition(target_point, QAngle(0,angle_rotated * (update_interval / pull_duration),0), unit:GetAbsOrigin()))
							local vacuum_center_distance = (target_point - unit:GetAbsOrigin()):Length2D()
							local vacuum_center_direction = (target_point - unit:GetAbsOrigin()):Normalized()
							-- overcomplicated shit to keep units moving at a constant rate towards the center, probably didn't need to implement it this way but oh well
							unit:SetAbsOrigin(unit:GetAbsOrigin() + vacuum_center_direction * vacuum_center_distance * (elapsed_time / pull_duration))
						end
						elapsed_time = elapsed_time + update_interval
						return update_interval
					else
						caster.bead_dummy_projectiles[dummy_projectile] = nil
						dummy_projectile:RemoveSelf()
						for k,bead in pairs(dummy_projectile.beads) do
							bead:RemoveSelf()
						end

						for k,unit in pairs(targets) do
							unit:RemoveModifierByName(keys.pull_modifier)
							FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
						end
					end
				end)
				
				

			end)
		end
	end)

	--------------------------------------------- Beads ---------------------------------------------
	local beads = math.ceil(2 * math.pi * radius / 120) -- 120 = arbitrary number to make the number of beads reasonable
	local unit_name = "npc_dummy_unit"

	-- Initialize the table to keep track of all beads
	dummy_projectile.beads = {}

	local particle = "particles/byakuren/bead_possibility_3.vpcf"
	for i=1,beads do
		local unit = CreateUnitByName(unit_name, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
		local particle = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, unit)
		-- ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_ABSORIGIN, "attach_origin", unit:GetAbsOrigin(), true)
		ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_ABSORIGIN, "attach_origin", unit:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(particle)

		ability:ApplyDataDrivenModifier(caster, unit, keys.bead_modifier, {})
		
		-- Add the spawned unit to the table
		table.insert(dummy_projectile.beads, unit)
	end
	
	dummy_projectile.beads_angle = 0
end

-- Movement logic for each bead
function updateBeads( event )
	local frozen = false
	local caster = event.caster
	local dummy_projectile = event.target
	local dummy_location = dummy_projectile:GetAbsOrigin()
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	local vertical_distance_offset = 80
	local rotation_time = 1.5
	local number_of_beads = #dummy_projectile.beads

	local rotation_point = dummy_location + Vector(0,0,1) * vertical_distance_offset

	-- Make beads spin
	dummy_projectile.beads_angle = dummy_projectile.beads_angle + (360 / rotation_time) * ability:GetLevelSpecialValueFor("update_interval", ability_level)

	local overallAngleInRadians = 0
	if not frozen then
		overallAngleInRadians = dummy_projectile.beads_angle * math.pi / 180
	end
	local prototype_target_point = rotation_point + Vector(math.sin(overallAngleInRadians), math.cos(overallAngleInRadians), 0) * radius

	for bead_number=1, number_of_beads do
		local angle = (360 / number_of_beads) * (bead_number - 1)
		local target_point = RotatePosition(rotation_point, QAngle(0,angle,0), prototype_target_point)
		local bead = dummy_projectile.beads[bead_number]
		if not bead:IsNull() then bead:SetAbsOrigin(target_point) end -- I still don't understand why this check is necessary, but whatever
	end
end

function updateAbilityActivated(keys)
	if keys.caster:HasModifier("modifier_vajrapanis_charges") then
		keys.ability:SetActivated(true)
	else
		keys.ability:SetActivated(false)
	end
end