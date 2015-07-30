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
		local column_point = target_point + right * (column_number - 1) * space_between_lines

		local dummy_modifier = keys.dummy_modifier
		local line_particle = keys.line_particle

		local line_length = height
		local line_end_point = column_point + back * height

		local direction_left = forward
		local direction_right = back

		-- Calculate the number of secondary dummies that we need to create
		local num_of_dummies = ((line_length - radius) / (radius*2))
		if num_of_dummies%2 ~= 0 then
			-- If its an uneven number then make the number even
			num_of_dummies = num_of_dummies + 1
		end

		-- Create the main line dummy
		local dummy = CreateUnitByName("npc_dummy_blank", column_point, false, caster, caster, caster_team)
		dummy:SetAbsOrigin(dummy:GetAbsOrigin() + height_increase)
		ability:ApplyDataDrivenModifier(caster, dummy, dummy_modifier, {})
		dummy.secondary_dummies = {}
		
		Timers:CreateTimer(duration, function()
			destroyLine(dummy)
		end)

		-- Create the secondary dummies for the line
		for i=1,num_of_dummies do
			-- Create a dummy on every interval point to fill the whole wall
			local temporary_point = column_point + (radius * 2 * i - radius) * back

			-- Create the secondary dummy and apply the dummy modifier to it
			local dummy_secondary = CreateUnitByName("npc_dummy_blank", temporary_point, false, caster, caster, caster_team)
			dummy_secondary:SetAbsOrigin(dummy_secondary:GetAbsOrigin() + height_increase)
			ability:ApplyDataDrivenModifier(dummy, dummy_secondary, dummy_modifier, {})
			table.insert(dummy.secondary_dummies, dummy_secondary)
		end

		-- Create the line particle
		local particle = ParticleManager:CreateParticle(line_particle, PATTACH_POINT_FOLLOW, dummy)
		ParticleManager:SetParticleControl(particle, 1, line_end_point + height_increase)
	end

	for row_number=1, rows do
		local row_point = target_point + back * (row_number - 1) * space_between_lines

		local dummy_modifier = keys.dummy_modifier
		local line_particle = keys.line_particle

		local line_length = width
		local line_end_point = row_point + right * width

		local direction_left = left
		local direction_right = right

		-- Calculate the number of secondary dummies that we need to create
		local num_of_dummies = ((line_length - radius) / (radius*2))
		if num_of_dummies%2 ~= 0 then
			-- If its an uneven number then make the number even
			num_of_dummies = num_of_dummies + 1
		end

		-- Create the main line dummy
		local dummy = CreateUnitByName("npc_dummy_blank", row_point, false, caster, caster, caster_team)
		dummy:SetAbsOrigin(dummy:GetAbsOrigin() + height_increase)
		ability:ApplyDataDrivenModifier(caster, dummy, dummy_modifier, {})
		dummy.secondary_dummies = {}
		
		Timers:CreateTimer(duration, function()
			destroyLine(dummy)
		end)

		-- Create the secondary dummies for the line
		for i=1,num_of_dummies do
			-- Create a dummy on every interval point to fill the whole wall
			local temporary_point = row_point + (radius * 2 * i - radius) * right

			-- Create the secondary dummy and apply the dummy modifier to it
			local dummy_secondary = CreateUnitByName("npc_dummy_blank", temporary_point, false, caster, caster, caster_team)
			dummy_secondary:SetAbsOrigin(dummy_secondary:GetAbsOrigin() + height_increase)
			ability:ApplyDataDrivenModifier(dummy, dummy_secondary, dummy_modifier, {})
			table.insert(dummy.secondary_dummies, dummy_secondary)
		end

		-- Create the line particle
		local particle = ParticleManager:CreateParticle(line_particle, PATTACH_POINT_FOLLOW, dummy)
		ParticleManager:SetParticleControl(particle, 1, line_end_point + height_increase)
	end
end

function checkForHits(keys)
	local target = keys.target
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local team = caster:GetTeamNumber()
	local origin = target:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_CLOSEST
	local radius = ability:GetLevelSpecialValueFor("line_radius", ability_level)

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	-- DebugDrawCircle(origin, Vector(0,255,0), 1, radius, true, 1)

	if #targets > 0 then
		-- I have no idea what causes this situation
		if not target.secondary_dummies and not target:FindModifierByName("modifier_dummy"):GetCaster().secondary_dummies then return end

		local unit = targets[1]

		-- if wasn't procced by main dummy, find main dummy
		if not target.secondary_dummies then
			target = target:FindModifierByName("modifier_dummy"):GetCaster()
		end
		caster = target:FindModifierByName("modifier_dummy"):GetCaster()

		local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
		local damage_type = ability:GetAbilityDamageType()

		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		ability:ApplyDataDrivenModifier(target:FindModifierByName("modifier_dummy"):GetCaster(), unit, keys.stun_modifier, {})

		destroyLine(target)
	end
end

function destroyLine(dummy)
	if not dummy:IsNull() then -- no clue if this is still necessary
		for k,secondary_dummy in pairs(dummy.secondary_dummies) do
			secondary_dummy:RemoveSelf()
		end
		dummy:RemoveSelf()
	end
end