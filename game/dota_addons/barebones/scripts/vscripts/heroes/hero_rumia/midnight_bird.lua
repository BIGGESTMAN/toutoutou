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
end