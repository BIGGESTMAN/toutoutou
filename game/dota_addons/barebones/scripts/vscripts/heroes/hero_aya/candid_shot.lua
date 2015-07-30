function candidShot(keys)
	local caster = keys.caster
	local target_location = keys.target_points[1]
	local caster_team = caster:GetTeamNumber()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local particle_duration = 0.5
	local width = ability:GetLevelSpecialValueFor("width", ability_level)
	local height = ability:GetLevelSpecialValueFor("height", ability_level)
	local aoe_loss_from_range = ability:GetLevelSpecialValueFor("aoe_loss_from_range", ability_level)
	local distance = (target_location - caster:GetAbsOrigin()):Length2D()
	local range = ability:GetCastRange()
	local aoe_loss = (distance / range) * aoe_loss_from_range
	local width = width - width * aoe_loss
	local height = height - height * aoe_loss

	local target_points = {}
	local angles = {}

	--1,2,3,4 is forward,right,back,left
	angles[1] = caster:GetForwardVector()
	for i=1,3 do
		angles[i + 1] = (RotatePosition(target_location, QAngle(0,90 * i,0), target_location + angles[1]) - target_location)
	end
	target_points[1] = target_location + angles[1] * height / 2
	target_points[2] = target_location + angles[2] * width / 2
	target_points[3] = target_location + angles[3] * height / 2
	target_points[4] = target_location + angles[4] * width / 2

	-- corners: 1,2,3,4 is ne, se, sw, nw (relative to cast)
	corner_points = {}
	corner_points[1] = target_points[1] + angles[2] * width / 2
	corner_points[2] = target_points[2] + angles[3] * height / 2
	corner_points[3] = target_points[3] + angles[4] * width / 2
	corner_points[4] = target_points[4] + angles[1] * height / 2

	-- Cosmetic variables
	local dummy_modifier = keys.dummy_modifier
	local wall_particle = keys.wall_particle
	local duration = ability:GetLevelSpecialValueFor("delay", ability_level)

	for i=1,4 do
		local point = corner_points[i]
		local connecting_point = nil
		if i < 4 then
			connecting_point = corner_points[i + 1]
		else
			connecting_point = corner_points[1]
		end

		local dummy = CreateUnitByName("npc_dummy_blank", point, false, caster, caster, caster_team)
		ability:ApplyDataDrivenModifier(caster, dummy, dummy_modifier, {})

		-- Create the wall particle
		local wall_particle = ParticleManager:CreateParticle(wall_particle, PATTACH_POINT_FOLLOW, dummy)
		ParticleManager:SetParticleControl(wall_particle, 1, connecting_point)

		Timers:CreateTimer(particle_duration,function()
			dummy:RemoveSelf()
		end)
	end

	-- End of delay, deal damage & stuff
	Timers:CreateTimer(duration,function()
		local team = caster:GetTeamNumber()
		local iTeam = DOTA_UNIT_TARGET_TEAM_BOTH
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local radius = math.sqrt(math.pow(width / 2, 2) + math.pow(height / 2, 2))

		local targets = FindUnitsInRadius(team, target_location, nil, radius, iTeam, iType, iFlag, iOrder, false)
		local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
		local damage_type = ability:GetAbilityDamageType()

		for k,unit in pairs(targets) do
			if pointIsInRectangle(unit:GetAbsOrigin(), corner_points) then
				if unit:GetTeamNumber() ~= caster:GetTeamNumber() then
					ApplyDamage({ victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					ability:ApplyDataDrivenModifier(caster, unit, keys.stun_modifier, {})

					local hit_particle = ParticleManager:CreateParticle(keys.enemy_hit_particle, PATTACH_POINT_FOLLOW, unit)
					ParticleManager:SetParticleControl(hit_particle, 0, unit:GetAbsOrigin())
					ParticleManager:SetParticleControl(hit_particle, 1, unit:GetAbsOrigin())
				else
					ProjectileManager:ProjectileDodge(unit)

					local hit_particle = ParticleManager:CreateParticle(keys.ally_hit_particle, PATTACH_POINT_FOLLOW, unit)
					ParticleManager:SetParticleControl(hit_particle, 0, unit:GetAbsOrigin())
					ParticleManager:SetParticleControl(hit_particle, 1, unit:GetAbsOrigin())
				end
			end
		end

		caster:EmitSound("barebones.Shutter")
	end)
end

function pointIsInRectangle(point, rectanglePoints)
	local sidesOfRectangle = {}
	sidesOfRectangle[1] = distance({rectanglePoints[1], rectanglePoints[2]})
	sidesOfRectangle[2] = distance({rectanglePoints[1], rectanglePoints[3]})
	sidesOfRectangle[3] = distance({rectanglePoints[1], rectanglePoints[4]})
	sidesOfRectangle[4] = distance({rectanglePoints[2], rectanglePoints[3]})
	sidesOfRectangle[5] = distance({rectanglePoints[2], rectanglePoints[4]})
	sidesOfRectangle[6] = distance({rectanglePoints[3], rectanglePoints[4]})
	for i = 1, 2 do
		for k,v in pairs(sidesOfRectangle) do
			if v == math.max(sidesOfRectangle[1] or 0, sidesOfRectangle[2] or 0, sidesOfRectangle[3] or 0,
							sidesOfRectangle[4] or 0, sidesOfRectangle[5] or 0, sidesOfRectangle[6] or 0) then
				sidesOfRectangle[k] = nil
				break
			end
		end
	end

	local rectanglePointPairs = {}
	if sidesOfRectangle[1] ~= nil then
		table.insert(rectanglePointPairs, {rectanglePoints[1], rectanglePoints[2]})
	end
	if sidesOfRectangle[2] ~= nil then
		table.insert(rectanglePointPairs, {rectanglePoints[1], rectanglePoints[3]})
	end
	if sidesOfRectangle[3] ~= nil then
		table.insert(rectanglePointPairs, {rectanglePoints[1], rectanglePoints[4]})
	end
	if sidesOfRectangle[4] ~= nil then
		table.insert(rectanglePointPairs, {rectanglePoints[2], rectanglePoints[3]})
	end
	if sidesOfRectangle[5] ~= nil then
		table.insert(rectanglePointPairs, {rectanglePoints[2], rectanglePoints[4]})
	end
	if sidesOfRectangle[6] ~= nil then
		table.insert(rectanglePointPairs, {rectanglePoints[3], rectanglePoints[4]})
	end
	local area1 = areaOfTriangle({point, rectanglePointPairs[1][1], rectanglePointPairs[1][2]})
	local area2 = areaOfTriangle({point, rectanglePointPairs[2][1], rectanglePointPairs[2][2]})
	local area3 = areaOfTriangle({point, rectanglePointPairs[3][1], rectanglePointPairs[3][2]})
	local area4 = areaOfTriangle({point, rectanglePointPairs[4][1], rectanglePointPairs[4][2]})
	local triangleAreaSum = area1 + area2 + area3 + area4
	-- i think actually only reliably works for squares?
	local rectangleArea = distance({rectanglePointPairs[1][1], rectanglePointPairs[1][2]}) *
							distance({rectanglePointPairs[2][1], rectanglePointPairs[2][2]})
	return triangleAreaSum <= rectangleArea * 1.01 -- god bless the united states of rounding errors
end

function areaOfTriangle(points)
	local lengths = {}
	lengths[1] = distance({points[1], points[2]})
	lengths[2] = distance({points[1], points[3]})
	lengths[3] = distance({points[2], points[3]})
	local semiperimeter = (lengths[1] + lengths[2] + lengths[3]) / 2
	return math.sqrt(semiperimeter * (semiperimeter - lengths[1]) * (semiperimeter - lengths[2]) * (semiperimeter - lengths[3]))
end

function distance(points)
	--return math.sqrt((math.abs(points[1][x] - points[2][x]))^2 + (math.abs(points[1][y] - points[2][y]))^2)
	return (points[1] - points[2]):Length2D()
end