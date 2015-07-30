function blink(keys)
	local target_point = keys.target_points[1]
	local caster = keys.caster
	local casterPos = caster:GetAbsOrigin()
	local distance = target_point - casterPos
	local ability = keys.ability
	local range = ability:GetLevelSpecialValueFor("range", (ability:GetLevel() - 1))

	if distance:Length2D() > range then
		target_point = casterPos + (target_point - casterPos):Normalized() * range
	end

	FindClearSpaceForUnit(caster, target_point, false)
	ProjectileManager:ProjectileDodge(caster)

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_ghost", {})

	-- if caster.anchors then
	-- 	for anchor,v in pairs(caster.anchors) do
	-- 		ability:ApplyDataDrivenModifier(caster, anchor, "modifier_anchor_ghost", {})
	-- 	end
	-- end
end