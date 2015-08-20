function unitsInLine(caster, ability, thinker_modifier, origin, range, radius, direction, grantVision, offset_forward, target_types, target_Flags)
	local thinkerRadius = radius * 1.5
	offset_forward = offset_forward or false
	target_types = target_types or DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	target_flags = target_flags or DOTA_UNIT_TARGET_FLAG_NONE

	local targets = {}

	local number_of_thinkers = math.ceil(range / radius)
	local distance_per_thinker = (range / number_of_thinkers)
	local thinkers = {}
	for i=1, number_of_thinkers do
		local thinker = CreateUnitByName("npc_dota_invisible_vision_source", origin, false, caster, caster, caster:GetTeam() )
		thinkers[i] = thinker

		if grantVision then
			thinker:SetDayTimeVisionRange( thinkerRadius )
			thinker:SetNightTimeVisionRange( thinkerRadius )
		end

		if offset_forward then
			thinker:SetAbsOrigin(origin + direction * (distance_per_thinker * (i) + thinkerRadius / 2))
		else
			thinker:SetAbsOrigin(origin + direction * (distance_per_thinker * (i - 1) + thinkerRadius / 2))
		end
		ability:ApplyDataDrivenModifier(caster, thinker, thinker_modifier, {})

		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = target_types
		local iFlag = target_flags
		local iOrder = FIND_CLOSEST

		-- DebugDrawCircle(thinker:GetAbsOrigin(), Vector(255,0,0), 1, thinkerRadius, true, 0.5)
		
		local possible_targets = FindUnitsInRadius(team, thinker:GetAbsOrigin(), nil, thinkerRadius, iTeam, iType, iFlag, iOrder, false)
		for k,possible_target in pairs(possible_targets) do
			-- Calculate distance
			local pathStartPos	= origin * Vector( 1, 1, 0 )
			local pathEndPos	= pathStartPos + direction * range

			local distance = DistancePointSegment(possible_target:GetAbsOrigin() * Vector( 1, 1, 0 ), pathStartPos, pathEndPos )
			if distance <= radius and not tableContains(targets, possible_target) then
				table.insert(targets, possible_target)
			end
		end
	end

	for k,thinker in pairs(thinkers) do
		thinker:RemoveSelf()
	end

	return targets
end

function tableContains(list, element)
    if list == nil then return false end
    for i=1,#list do
        if list[i] == element then
            return true
        end
    end
    return false
end

function DistancePointSegment( p, v, w )
	local l = w - v
	local l2 = l:Dot( l )
	t = ( p - v ):Dot( w - v ) / l2
	if t < 0.0 then
		return ( v - p ):Length2D()
	elseif t > 1.0 then
		return ( w - p ):Length2D()
	else
		local proj = v + t * l
		return ( proj - p ):Length2D()
	end
end

function GetEnemiesInCone(unit, start_radius, end_radius, end_distance, caster_forward, circles, debug, target_flags)
	local DEBUG = debug or false
	
	-- Positions
	local fv = caster_forward
	local origin = unit:GetAbsOrigin()

	local start_point = origin + fv * start_radius -- Position to find units with start_radius
	local end_point = origin + fv * (start_radius + end_distance) -- Position to find units with end_radius

	if DEBUG then
		DebugDrawCircle(start_point, Vector(255,0,0), 5, start_radius, true, 1)
		DebugDrawCircle(end_point, Vector(255,0,0), 5, end_radius, true, 1)
	end

	local intermediate_circles = {}
	local number_of_intermediate_circles = circles - 2
	for i=1,number_of_intermediate_circles do
		local radius = start_radius + (end_radius - start_radius) / (number_of_intermediate_circles + 1) * i
		local point = origin + fv * (end_distance / (number_of_intermediate_circles + 1) * i + start_radius)
		intermediate_circles[i] = {point = point, radius = radius}
	end
	
	if DEBUG then
		for k,circle in pairs(intermediate_circles) do 
			DebugDrawCircle(circle.point, Vector(0,255,0), 5, circle.radius, true, 1)
		end
	end

	local cone_units = {}
	-- Find the units
	local team = unit:GetTeamNumber()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = target_flags or DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER

	local start_units = FindUnitsInRadius(team, start_point, nil, start_radius, iTeam, iType, iFlag, iOrder, false)
	local end_units = FindUnitsInRadius(team, end_point, nil, end_radius, iTeam, iType, iFlag, iOrder, false)

	-- Join the tables
	for k,v in pairs(end_units) do
		table.insert(cone_units, v)
	end

	for k,v in pairs(start_units) do
		if not tableContains(cone_units, v) then
			table.insert(cone_units, v)
		end
	end

	for k,circle in pairs(intermediate_circles) do
		local units = FindUnitsInRadius(team, circle.point, nil, circle.radius, iTeam, iType, iFlag, iOrder, false)
		for k,v in pairs(units) do
			if not tableContains(cone_units, v) then
				table.insert(cone_units, v)
			end
		end
	end

	--	DeepPrintTable(cone_units)

	return cone_units
end

function randomIndexOfTable(table, excluded_indices)
	local excluded = excluded_indices or {}

	local indexes = {}
	for k,v in pairs(table) do
		if not tableContains(excluded_indices, k) then
			indexes[#indexes + 1] = k
		end
	end
	
	return indexes[RandomInt(1, #indexes)]
end

function sizeOfTable(table)
	local size = 0
	for k,v in pairs(table) do
		size = size + 1
	end
	return size
end