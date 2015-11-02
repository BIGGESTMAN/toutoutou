require "libraries/util"

function drawLines(keys)
	local caster = keys.caster
	local caster_location = caster:GetAbsOrigin()
	local caster_team = caster:GetTeamNumber()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local forward = caster:GetForwardVector()
	local back = RotatePosition(Vector(0,0,0), QAngle(0,180,0), forward)
	local left = RotatePosition(Vector(0,0,0), QAngle(0,90,0), forward)
	local right = RotatePosition(Vector(0,0,0), QAngle(0,-90,0), forward)
	local space_between_lines = ability:GetLevelSpecialValueFor("space_between_lines", ability_level) 
	local columns = 5 -- vertical lines
	local rows = 4 -- horizontal lines
	local width = (columns - 1) * space_between_lines
	local height = (rows - 1) * space_between_lines
	local target_point = keys.target_points[1] + (width / 2) * left + (height / 2) * forward -- Top-left corner
	local height_increase = Vector(0,0,100)

	local duration = ability:GetLevelSpecialValueFor("line_duration", ability_level)
	local radius = ability:GetLevelSpecialValueFor("line_radius", ability_level)

	-- Make columns
	for column_number=1, columns do
		local line_start = target_point + right * (column_number - 1) * space_between_lines
		local line_end = line_start + back * height

		-- Create line dummy
		local dummy = CreateUnitByName("npc_dummy_unit", line_start, false, caster, caster, caster_team)
		ability:ApplyDataDrivenModifier(caster, dummy, "modifier_nine_character_pierce_line_dummy", {})
		ability:ApplyDataDrivenModifier(caster, dummy, "modifier_kill", {duration = duration})
		dummy:SetAbsOrigin(dummy:GetAbsOrigin() + height_increase)
		dummy.direction = back
		dummy.length = height
		
		-- Create line particle
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_dreamcoil_tether.vpcf", PATTACH_POINT, dummy)
		ParticleManager:SetParticleControl(particle, 1, line_end + height_increase)
	end

	-- Make rows
	for row_number=1, rows do
		local line_start = target_point + back * (row_number - 1) * space_between_lines
		local line_end = line_start + right * width

		-- Create line dummy
		local dummy = CreateUnitByName("npc_dummy_unit", line_start, false, caster, caster, caster_team)
		ability:ApplyDataDrivenModifier(caster, dummy, "modifier_nine_character_pierce_line_dummy", {})
		ability:ApplyDataDrivenModifier(caster, dummy, "modifier_kill", {duration = duration})
		dummy:SetAbsOrigin(dummy:GetAbsOrigin() + height_increase)
		dummy.direction = right
		dummy.length = width

		-- Create line particle
		local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_puck/puck_dreamcoil_tether.vpcf", PATTACH_POINT, dummy)
		ParticleManager:SetParticleControl(particle, 1, line_end + height_increase)
	end
end

function checkForHits(keys)
	local line_dummy = keys.target
	if line_dummy.direction then -- A hacky fix for a bug i do not understand at all
		local caster = keys.caster
		local ability = keys.ability

		local origin = line_dummy:GetAbsOrigin()
		local length = line_dummy.length
		local radius = ability:GetSpecialValueFor("line_radius")
		local direction = line_dummy.direction

		local targets = unitsInLine(caster, origin, length, radius, direction, false)

		if #targets > 0 then
			local unit = targets[1]
			local damage = ability:GetSpecialValueFor("damage")
			local damage_type = ability:GetAbilityDamageType()

			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_nine_character_pierce_stun", {})

			line_dummy:RemoveSelf()
		end
	end
end