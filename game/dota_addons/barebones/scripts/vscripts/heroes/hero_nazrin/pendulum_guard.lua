function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	ability:ApplyDataDrivenModifier(caster, target, "modifier_pendulum_guard", {})
	if not target.pendulum_guard_damage_absorbed then target.pendulum_guard_damage_absorbed = 0 end
end

function durationEnded(keys)
	local caster = keys.caster
	local target = keys.target

	caster:GiveMana(target.pendulum_guard_damage_absorbed)
	target.pendulum_guard_damage_absorbed = nil
end