function unitsInLine(caster, ability, thinker_modifier, origin, range, radius, direction, grantVision)
	local thinkerRadius = radius * 1.5

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

		thinker:SetAbsOrigin(origin + direction * (distance_per_thinker * (i-1) + thinkerRadius / 2))
		ability:ApplyDataDrivenModifier(caster, thinker, thinker_modifier, {})

		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_CLOSEST

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