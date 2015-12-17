function updateVision(keys)
	local caster = keys.caster
	AddFOWViewer(caster:GetTeamNumber(), caster:GetAbsOrigin(), 1800, 0.03, false)
end

function swoop(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- caster:Stop()
	-- caster:Interrupt()
	caster:RemoveModifierByName("modifier_queen_of_midnight")
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_queen_of_midnight_swooping", {})

	local speed = ability:GetLevelSpecialValueFor("swoop_speed", ability_level) * 0.03
	local arrival_distance = caster:GetAttackRange()
	local target_point = target:GetAbsOrigin()

	Timers:CreateTimer(0, function()
		if not target:IsNull() then target_point = target:GetAbsOrigin() end
		local caster_location = caster:GetAbsOrigin()
		local distance = (target_point - caster_location):Length2D()
		local direction = (target_point - caster_location):Normalized()
		if distance > arrival_distance then
			caster:SetAbsOrigin(caster_location + direction * speed)
			return 0.03
		else
			FindClearSpaceForUnit(caster, caster:GetAbsOrigin(), false)
			direction = (target_point - caster:GetAbsOrigin()):Normalized()
			caster:SetForwardVector(direction)
			
			caster:PerformAttack(target, true, true, false, false, false)
			ability:ApplyDataDrivenModifier(caster, target, "modifier_queen_of_midnight_stun", {})
			caster:AttackNoEarlierThan(caster:GetSecondsPerAttack())
			caster:RemoveModifierByName("modifier_queen_of_midnight_swooping")
		end
	end)
end