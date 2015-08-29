require "libraries/util"

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target_point = keys.target_points[1]
	DebugDrawCircle(target_point, Vector(0,255,0), 1, 30, true, 0.5)

	local damage = ability:GetSpecialValueFor("damage")
	local damage_type = ability:GetAbilityDamageType()
	echoDamage(caster, damage, damage_type)

	local duration = ability:GetSpecialValueFor("duration") / 5
	local length = ability:GetLevelSpecialValueFor("tear_length", ability_level)
	local width = ability:GetLevelSpecialValueFor("tear_width", ability_level)

	local forward = (target_point - caster:GetAbsOrigin()):Normalized()
	local right = RotatePosition(Vector(0,0,0), QAngle(0,-90,0), forward)
	local line_start = target_point + right * -1 * length / 2
	DebugDrawCircle(line_start, Vector(0,255,255), 1, 30, true, 0.5)

	local tear_dummy = CreateUnitByName("npc_dummy_unit", target_point, false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, tear_dummy, dummy_modifier, {})
	ability:ApplyDataDrivenModifier(caster, tear_dummy, "modifier_kill", {duration = duration})
	tear_dummy.forward = forward

	if not caster.eternal_truth_tears then caster.eternal_truth_tears = {} end
	table.insert(caster.eternal_truth_tears, tear_dummy)

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_eternal_truth_tear_tracker", {duration = duration})

	local targets = unitsInLine(caster, ability, line_start, length, width, right, false, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL)

	for k,unit in pairs(targets) do
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
	end
end

function echoDamage(caster, damage, damage_type)
	if caster.eternal_truth_tears then
		local ability = caster:FindAbilityByName("eternal_truth")
		local length = ability:GetSpecialValueFor("tear_length")
		local width = ability:GetSpecialValueFor("tear_width")
		local dummy_modifier = "modifier_eternal_truth_dummy"

		local hit_units = {}
		for k,tear in pairs(caster.eternal_truth_tears) do
			if not tear:IsNull() then
				local right = RotatePosition(Vector(0,0,0), QAngle(0,-90,0), tear.forward)
				local line_start = tear:GetAbsOrigin() + right * -1 * length / 2
				local targets = unitsInLine(caster, ability, dummy_modifier, line_start, length, width, right, false, false, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL)
				for _,unit in pairs(targets) do
					if not tableContains(hit_units, unit) then
						table.insert(hit_units, unit)
					end
				end
			else
				table.remove(caster.eternal_truth_tears, k)
			end
		end

		local damage = damage * ability:GetSpecialValueFor("echo_damage_percent") / 100
		for k,unit in pairs(hit_units) do
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_eternal_truth_slow", {})
		end
	end
end

function attackLanded(keys)
	print(keys.caster, keys.damage_dealt)
	echoDamage(keys.caster, keys.damage_dealt, DAMAGE_TYPE_PHYSICAL)
end