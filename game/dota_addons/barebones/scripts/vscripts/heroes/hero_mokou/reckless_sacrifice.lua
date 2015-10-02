require "libraries/util"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local flames = ability:GetSpecialValueFor("flames")

	for i=1,flames do
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_reckless_sacrifice_flame", {})
	end
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_reckless_sacrifice_tracker", {})
end

function attackLanded(keys)
	local caster = keys.caster
	local attacker = keys.attacker
	local target = keys.target
	local ability = keys.ability
	if caster == attacker then
		caster:FindModifierByName("modifier_reckless_sacrifice_flame"):Destroy()

		ability:ApplyDataDrivenModifier(caster, target, "modifier_reckless_sacrifice_flame", {})
		ability:ApplyDataDrivenModifier(caster, target, "modifier_reckless_sacrifice_tracker", {})
		local flame_stacks = getNumberOfModifierInstances(target, "modifier_reckless_sacrifice_flame")
		if flame_stacks >= 2 then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_reckless_sacrifice_damage_reduction", {})
		end
		if flame_stacks >= 3 then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_reckless_sacrifice_disarm", {})
		end
	end
end

function flameEnded(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local flame_stacks = getNumberOfModifierInstances(target, "modifier_reckless_sacrifice_flame")
	if flame_stacks < 3 then
		target:RemoveModifierByName("modifier_reckless_sacrifice_disarm")
	end
	if flame_stacks < 2 then
		target:RemoveModifierByName("modifier_reckless_sacrifice_damage_reduction")
	end

	if not target:HasModifier("modifier_reckless_sacrifice_flame") then
		target:RemoveModifierByName("modifier_reckless_sacrifice_tracker")
		if target.reckless_flame_particle_dummies then
			for k,dummy in pairs(target.reckless_flame_particle_dummies) do
				destroyFlameDummy(dummy)
			end
			target.reckless_flame_particle_dummies = nil
			target.reckless_flame_angle = nil
		end
	end
end

function updateFlameParticles(keys)
	local target = keys.target
	local ability = keys.ability

	local update_interval = ability:GetSpecialValueFor("update_interval")
	local vertical_offset = 80
	local rotation_time = 1
	local angle_increment = (360 / rotation_time) * update_interval
	local radius = 75

	local flame_stacks = getNumberOfModifierInstances(target, "modifier_reckless_sacrifice_flame")

	if not target.reckless_flame_particle_dummies then target.reckless_flame_particle_dummies = {} end
	if not target.reckless_flame_angle then target.reckless_flame_angle = 0 end

	while flame_stacks > #target.reckless_flame_particle_dummies do
		local dummy = CreateUnitByName("npc_dummy_unit", target:GetAbsOrigin(), false, target, target, target:GetTeamNumber())
		ability:ApplyDataDrivenModifier(target, dummy, "modifier_reckless_sacrifice_dummy", {})
		dummy.particle = ParticleManager:CreateParticle("particles/mokou/reckless_sacrifice/flame.vpcf", PATTACH_ABSORIGIN, dummy)
		ParticleManager:SetParticleControlEnt(dummy.particle, 0, dummy, PATTACH_POINT_FOLLOW, "attach_origin", dummy:GetAbsOrigin(), true)
		table.insert(target.reckless_flame_particle_dummies, dummy)
	end

	local rotation_point = target:GetAbsOrigin() + Vector(0,0,1) * vertical_offset
	local overallAngleInRadians = target.reckless_flame_angle * math.pi / 180
	local prototype_target_point = rotation_point + Vector(math.sin(overallAngleInRadians), math.cos(overallAngleInRadians), 0) * radius

	for flame_number=1, flame_stacks do
		local angle = (360 / flame_stacks) * (flame_number - 1)
		local target_point = RotatePosition(rotation_point, QAngle(0,angle,0), prototype_target_point)
		target.reckless_flame_particle_dummies[flame_number]:SetAbsOrigin(target_point)
	end

	while flame_stacks < #target.reckless_flame_particle_dummies do
		destroyFlameDummy(target.reckless_flame_particle_dummies[1])
		table.remove(target.reckless_flame_particle_dummies, 1)
	end

	target.reckless_flame_angle = target.reckless_flame_angle + angle_increment
end

function destroyFlameDummy(dummy)
	ParticleManager:DestroyParticle(dummy.particle, false)
	dummy:RemoveSelf()
end