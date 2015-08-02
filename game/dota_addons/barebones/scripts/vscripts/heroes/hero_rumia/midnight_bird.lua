function midnightBirdCast(keys)
	-- local entity = Entities:CreateByClassname("ent_fow_blocker_node")
	-- local entity = Entities:CreateByClassname("point_simple_obstruction")
	-- local entity = SpawnEntityFromTableSynchronous("point_simple_obstruction", {origin = keys.caster:GetAbsOrigin()})
	-- -- entity:SetAbsOrigin(keys.caster:GetAbsOrigin())
	-- -- entity:Trigger()
	-- entity:SetEnabled(true, true)
	-- -- Timers:CreateTimer(0, function()
	-- -- 	print(entity:GetAbsOrigin())
	-- -- 	return 0.5
	-- -- end)


	-- local caster = keys.caster
	-- local ability = keys.ability
	-- local ability_level = ability:GetLevel() - 1
	-- local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	-- local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	
	-- local target_point = caster:GetAbsOrigin()
	-- local tree_count = 8
	-- for i=1,tree_count do
	-- 	local vector = RotatePosition(Vector(0,0,0), QAngle(0,i * 360 / tree_count,0), caster:GetForwardVector())
	-- 	local target = target_point + vector * radius
	-- 	CreateTempTree(target, duration)
	-- end

	-- local trees = GridNav:GetAllTreesAroundPoint(target_point, radius, true)
	-- for k,v in pairs(trees) do
	-- 	for k2,v2 in pairs(v) do
	-- 		print(k2,v2)
	-- 	end
	-- end

	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	GameRules:SetCustomGameTeamMaxPlayers(6, 10)
	local dummy_unit = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_unit, keys.dummy_modifier, {})
	local vision_dummy = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, 6)
	ability:ApplyDataDrivenModifier(caster, vision_dummy, "modifier_midnight_bird_vision_dummy", {})
	Timers:CreateTimer(ability:GetLevelSpecialValueFor("duration", ability_level), function()
		vision_dummy:RemoveSelf()
	end)
	-- AddFOWViewer(6, dummy_unit:GetAbsOrigin(), ability:GetLevelSpecialValueFor("radius", ability_level), ability:GetLevelSpecialValueFor("duration", ability_level), true)

	Timers:CreateTimer(ability:GetLevelSpecialValueFor("duration", ability_level), function()
		dummy_unit:RemoveSelf()
	end)
end

function midnightBirdAOE(keys)
	-- print("!")
	-- local caster = keys.caster
	-- local ability = keys.ability
	-- local ability_level = ability:GetLevel() - 1
	-- local target = keys.target

	-- local team = caster:GetTeamNumber()
	-- local origin = target:GetAbsOrigin()
	-- local iTeam = DOTA_UNIT_TARGET_TEAM_BOTH
	-- local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_HERO
	-- local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	-- local iOrder = FIND_ANY_ORDER
	-- local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

	-- local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	-- for k,unit in pairs(targets) do
	-- 	print("?")
	-- 	ability:ApplyDataDrivenModifier(caster, unit, "modifier_midnight_bird_blinded", {})
	-- end
end

function blinded(keys)
	local playerID = keys.target:GetPlayerID()
	PlayerResource:SetCustomTeamAssignment(playerID, 6)
	print(PlayerResource:GetTeam(playerID))
end

function unBlinded(keys)
	local playerID = keys.target:GetPlayerID()
	PlayerResource:SetCustomTeamAssignment(playerID, keys.target:GetTeamNumber())
end