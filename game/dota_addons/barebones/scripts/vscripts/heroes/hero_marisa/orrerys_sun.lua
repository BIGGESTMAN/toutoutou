require "libraries/util"

SPARK_MODIFIERS = {"modifier_master_spark", "modifier_final_spark"}

function orrerysSunStart( event )
	local caster = event.caster
	if (caster:IsAlive()) then
		local ability = event.ability
		local orbs = ability:GetLevelSpecialValueFor( "orbs", ability:GetLevel() - 1 )
		-- local orbs = 1
		local unit_name = "orrerys_sun_orb"

		-- Initialize the table to keep track of all orbs
		if caster.orbs then
			for k,orb in pairs(caster.orbs) do
				orb:RemoveSelf()
			end
		end
		caster.orbs = {}

		local particles = {"particles/orrerys_sun_yellow.vpcf", "particles/orrerys_sun_green.vpcf", "particles/orrerys_sun_orange.vpcf",
						   "particles/orrerys_sun_pink.vpcf", "particles/orrerys_sun_blue.vpcf", "particles/orrerys_sun_red.vpcf"}
		for i=1,orbs do
			local unit = CreateUnitByName(unit_name, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
			local particle = ParticleManager:CreateParticle(particles[#caster.orbs + 1], PATTACH_ABSORIGIN, unit)
			ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_ABSORIGIN, "attach_origin", unit:GetAbsOrigin(), true)
			ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_ABSORIGIN, "attach_origin", unit:GetAbsOrigin(), true)

			ability:ApplyDataDrivenModifier(caster, unit, "modifier_orrerys_sun_orb", {})
			
			-- Add the spawned unit to the table
			table.insert(caster.orbs, unit)
		end
		
		caster.orbs_angle = 0
	end
end

-- Movement logic for all orbs
function updateOrbs( event )
	local frozen = false

	local caster = event.caster
	local caster_location = caster:GetAbsOrigin()
	local ability = event.ability
	local vertical_distance_from_caster = ability:GetLevelSpecialValueFor( "vertical_distance_from_caster", ability:GetLevel() - 1 )
	local number_of_orbs = #caster.orbs
	local update_interval = ability:GetLevelSpecialValueFor("orb_update_interval", ability:GetLevel() - 1)

	local spark_tilt_angle = 90
	local total_spark_tilt_time = 1
	local spark_velocity_factors = {4,5} -- Depending on which spark is used
	local spark_tilt_increase_per_tick = spark_tilt_angle * update_interval / total_spark_tilt_time

	-- Rapidly tilt backwards if firing Master or Final Spark
	local firing_spark = nil
	for k,modifier in pairs(SPARK_MODIFIERS) do
		if caster:HasModifier(modifier) then
			firing_spark = true
			caster.spark_type = k
			break
		end
	end

	if firing_spark then
		if not caster.spark_tilt_angle then caster.spark_tilt_angle = 0 end
		caster.spark_tilt_angle = caster.spark_tilt_angle + spark_tilt_increase_per_tick
		if caster.spark_tilt_angle > spark_tilt_angle then caster.spark_tilt_angle = spark_tilt_angle end
	else -- Tilt back down after spark
		if caster.spark_tilt_angle then
			caster.spark_tilt_angle = caster.spark_tilt_angle - spark_tilt_increase_per_tick
			if caster.spark_tilt_angle <= 0 then caster.spark_tilt_angle = nil end
		end
	end

	local radius = ability:GetLevelSpecialValueFor( "radius", ability:GetLevel() - 1 )
	if caster.spark_tilt_angle and caster.spark_type == 2 then -- Increase circle radius a little during Final Spark
		radius = radius * (1 + 0.5 * caster.spark_tilt_angle / spark_tilt_angle)
	end

	local rotation_point = caster_location + Vector(0,0,1) * vertical_distance_from_caster
	if caster.spark_tilt_angle and caster.spark_type == 2 then -- Move center of circle to Marisa during Final Spark if orbs are tilted
		local offset_y = math.sin(caster.spark_tilt_angle * math.pi / 180) * radius * caster.spark_tilt_angle / spark_tilt_angle
		local offset_x = math.sin(caster.spark_tilt_angle * math.pi / 180) * radius * caster.spark_tilt_angle / spark_tilt_angle
		local circle_offset = offset_x * caster:GetForwardVector() + offset_y * Vector(0,0,-1)
		rotation_point = rotation_point + circle_offset
	end

	-- Make orbs spin
	local rotation_time = ability:GetLevelSpecialValueFor("rotation_time", ability:GetLevel() - 1)
	local angle_increment = (360 / rotation_time) * update_interval
	if caster.spark_tilt_angle then -- Increase speed as orbs tilt back during spark
		angle_increment = angle_increment * (1 + (spark_velocity_factors[caster.spark_type] - 1) * caster.spark_tilt_angle / spark_tilt_angle)
	end
	caster.orbs_angle = caster.orbs_angle + angle_increment

	local overallAngleInRadians = 0
	if not frozen then
		overallAngleInRadians = caster.orbs_angle * math.pi / 180
	end
	local prototype_target_point = rotation_point + Vector(math.sin(overallAngleInRadians), math.cos(overallAngleInRadians), 0) * radius

	for orb_number=1, number_of_orbs do
		local angle = (360 / number_of_orbs) * (orb_number - 1)
		local target_point = RotatePosition(rotation_point, QAngle(0,angle,0), prototype_target_point)

		if firing_spark then
			target_point = tiltOrb(rotation_point, target_point, caster.spark_tilt_angle, caster:GetForwardVector())
		else -- Tilt back down after spark
			if caster.spark_tilt_angle then
				target_point = tiltOrb(rotation_point, target_point, caster.spark_tilt_angle, caster:GetForwardVector())
			end
		end
		caster.orbs[orb_number]:SetAbsOrigin(target_point)
	end
end

function tiltOrb(origin, orb_location, angle, forward)
	local debug = false
	if debug then DebugDrawCircle(orb_location, Vector(255,255,255), 1, 25, true, 0.5) end
	local angle_vector = orb_location - origin
	local forward_angle = vectorToAngle(forward, "degrees")
	-- print("forward angle:",forward_angle)
	local adjusted_orb_location = RotatePosition(origin, QAngle(0,forward_angle,0),orb_location)
	local radians_angle = vectorToAngle(adjusted_orb_location - origin)
	local radius = (orb_location - origin):Length2D()
	-- print("angle in radians:", radians_angle)
	local quadrant = math.ceil(radians_angle / (math.pi / 2))
	-- print("quadrant:", quadrant)
	local effective_angle = nil
	local distance_to_back = nil
	if quadrant == 1 then
		effective_angle = radians_angle
		distance_to_back = radius + math.sin(effective_angle) * radius
	elseif quadrant == 2 then
		effective_angle = math.pi - radians_angle
		distance_to_back = radius + math.sin(effective_angle) * radius
	elseif quadrant == 3 then
		effective_angle = radians_angle - math.pi
		distance_to_back = radius - math.sin(effective_angle) * radius
	elseif quadrant == 4 then
		effective_angle = math.pi * 2 - radians_angle
		distance_to_back = radius - math.sin(effective_angle) * radius
	end
	-- print("distance:",distance_to_back)
	local back_of_circle = origin + forward * -1 * radius
	-- DebugDrawCircle(back_of_circle, Vector(255,255,255), 1, 25, true, 0.5)
	local left = RotatePosition(Vector(0,0,0), QAngle(0,-90,0), forward)
	if debug then DebugDrawLine(back_of_circle + left * -300, left * 300 + back_of_circle, 255, 0, 0, true, 0.25) end
	local rotation_point = orb_location + forward * -1 * distance_to_back
	if debug then DebugDrawLine(rotation_point, orb_location, 0, 255, 0, true, 0.25) end
	-- DebugDrawCircle(rotation_point, Vector(255,0,0), 1, 50, true, 0.5)

	local height = math.sin(angle * math.pi / 180) * distance_to_back
	local width = math.cos(angle * math.pi / 180) * distance_to_back

	local up = Vector(0,0,1)
	local tilted_location = rotation_point + width * forward + height * up

	-- DebugDrawLine(orb_location, origin, 0,0,255, true, 0.25)
	-- print((rotation_point - orb_location):Normalized(), effective_angle * 180 / math.pi)
	-- local facing_angle = vectorToAngle(forward)
	-- print(math.sin(facing_angle), math.cos(facing_angle))

	-- local tilted_location = RotatePosition(rotation_point, QAngle(-1 * (90 - angle) * math.cos(facing_angle), 0, (90 - angle) * math.sin(facing_angle)), orb_location)

	-- local test_raised_position = distance_to_back * up + rotation_point
	-- if debug then DebugDrawLine(rotation_point, test_raised_position, 0, 0, 255, true, 0.25) end
	-- local height = tilted_location.z - orb_location.z
	-- local test_lowered_position = tilted_location + up * -1 * height
	-- if debug then DebugDrawLine(tilted_location, test_lowered_position, 0, 0, 255, true, 0.25) end
	-- if debug then DebugDrawLine(tilted_location, orb_location, 0, 255, 0, true, 0.25) end
	return tilted_location
	-- return orb_location
end

function vectorToAngle(vector, angle_type)
	angle_type = angle_type or "radians"
	if angle_type == "degrees" then
		return (90 - (math.atan2(vector.y, vector.x) * 180 / math.pi)) % 360
	else
		return (math.atan2(vector.y, vector.x)) % (math.pi * 2)
	end
end

-- Fire autoattack bolts when caster attacks
function orrerysSunAttack( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability
	local orb_firing_time = ability:GetSpecialValueFor("orb_firing_time")
	local delay = orb_firing_time / (#caster.orbs - 1)
	-- print(delay)

	for i=1,#caster.orbs do
		Timers:CreateTimer((i - 1) * delay, function()
			if caster.orbs[i] then
				caster.orbs[i]:PerformAttack(target, true, true, true, true )
			end
		end)
	end
end

function orbAttackHit( event )
	local caster = event.caster
	local target = event.target
	local ability = event.ability

	local damage_table = {}
		damage_table.attacker = caster
		damage_table.victim = target
		damage_table.damage_type = DAMAGE_TYPE_PHYSICAL
		damage_table.ability = ability
		damage_table.damage = caster:GetAverageTrueAttackDamage() / 10

	ApplyDamage(damage_table)
end

-- Remove orbs when caster dies
function endOrrerysSun( event )
	local caster = event.caster
	local targets = caster.orbs or {}

	for _,unit in pairs(targets) do
	   	if unit and IsValidEntity(unit) then
	        unit:RemoveSelf()
    	end
	end

	caster.orbs = {}
	caster.orbs_angle = 0
end

function spellCast( event )
	local caster = event.caster
	if not event.event_ability:IsItem() and event.event_ability ~= caster:FindAbilityByName("blazing_star_reverse") then
		fireLasers(caster, event.ability)
	end
end

function fireLasers(caster, ability)
	local orb_firing_time = ability:GetSpecialValueFor("orb_firing_time")
	local delay = orb_firing_time / (#caster.orbs - 1)

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_CLOSEST

	for i=1,#caster.orbs do
		Timers:CreateTimer((i - 1) * delay, function()
			fireLaser(caster, ability, caster.orbs[i])
		end)
	end
end

function fireLaser(caster, ability, orb)
	local ability_level = ability:GetLevel() - 1
	local search_radius = ability:GetLevelSpecialValueFor("search_radius", ability_level)

	local team = caster:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_CLOSEST

	local units = FindUnitsInRadius(team, orb:GetAbsOrigin(), nil, search_radius, iTeam, iType, iFlag, iOrder, false)
	if #units > 0 then
		local target = units[RandomInt(1, #units)]
		fireLaserAt(caster, ability, orb, target)
		orb:EmitSound("Hero_Tinker.Laser")
	end
end

function fireLaserAt(caster, ability, orb, target)
	local orb_location = orb:GetAbsOrigin()
	local ability_level = ability:GetLevel() - 1
	local range = ability:GetLevelSpecialValueFor("search_radius", ability_level)
	local radius = ability:GetLevelSpecialValueFor("laser_radius", ability_level)
	local particle_name = "particles/units/heroes/hero_tinker/tinker_laser.vpcf"
	local targetDirection = (target:GetAbsOrigin() - orb_location):Normalized()

	local targets = unitsInLine(caster, ability, orb_location, range, radius, targetDirection, true)

	--print("laser hit target:", tableContains(targets, target))

	for k,unit in pairs(targets) do
		ApplyDamage({ victim = unit, attacker = caster, damage = ability:GetLevelSpecialValueFor("laser_damage", ability_level),
					damage_type = ability:GetAbilityDamageType()})
	end

	-- Particle
	local particle = ParticleManager:CreateParticle(particle_name, PATTACH_POINT_FOLLOW, orb)
	ParticleManager:SetParticleControl(particle,9,orb_location)	
	ParticleManager:SetParticleControl(particle,1,target:GetAbsOrigin())
	ParticleManager:SetParticleControl(particle,0,orb_location)

	-- Sound
	-- orb:EmitSound("Hero_Tinker.Laser")
end