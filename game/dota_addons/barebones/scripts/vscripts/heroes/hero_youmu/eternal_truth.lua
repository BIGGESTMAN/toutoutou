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
	ability:ApplyDataDrivenModifier(caster, tear_dummy, "modifier_eternal_truth_dummy", {duration = duration})
	tear_dummy.forward = forward

	if not caster.eternal_truth_tears then caster.eternal_truth_tears = {} end
	caster.eternal_truth_tears[tear_dummy] = true

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_eternal_truth_tear_tracker", {duration = duration})

	local targets = unitsInLine(caster, ability, line_start, length, width, right, false, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL)

	for k,unit in pairs(targets) do
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
	end

	local line_end = target_point + right * length / 2
	local particle = ParticleManager:CreateParticle("particles/youmu/eternal_truth_slash.vpcf", PATTACH_ABSORIGIN, tear_dummy)
	ParticleManager:SetParticleControl(particle, 0, line_start)
	ParticleManager:SetParticleControl(particle, 1, line_end)

	local tear_particle_delay = 0.15
	Timers:CreateTimer(tear_particle_delay, function()
		tear_dummy.tear_particle = ParticleManager:CreateParticle("particles/youmu/eternal_truth_tear.vpcf", PATTACH_ABSORIGIN, tear_dummy)
		ParticleManager:SetParticleControl(tear_dummy.tear_particle, 1, line_end)
		ParticleManager:SetParticleControl(tear_dummy.tear_particle, 2, line_start)
		ParticleManager:SetParticleControl(tear_dummy.tear_particle, 3, line_end)
	end)
end

function destroyTearDummy(keys)
	local tear_dummy = keys.target
	ParticleManager:DestroyParticle(tear_dummy.tear_particle, false)
	keys.caster.eternal_truth_tears[tear_dummy] = nil
	tear_dummy:RemoveSelf()
end

function echoDamage(caster, damage, damage_type)
	if caster.eternal_truth_tears then
		local ability = caster:FindAbilityByName("eternal_truth")
		local length = ability:GetSpecialValueFor("tear_length")
		local width = ability:GetSpecialValueFor("tear_width")

		local hit_units = {}
		for tear,__ in pairs(caster.eternal_truth_tears) do
			if not tear:IsNull() then
				local right = RotatePosition(Vector(0,0,0), QAngle(0,-90,0), tear.forward)
				local line_start = tear:GetAbsOrigin() + right * -1 * length / 2
				local line_end = tear:GetAbsOrigin() + right * length / 2
				local targets = unitsInLine(caster, ability, line_start, length, width, right, false, DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL)
				for _,unit in pairs(targets) do
					if not tableContains(hit_units, unit) then
						table.insert(hit_units, unit)
					end
				end

				echo_particle = ParticleManager:CreateParticle("particles/youmu/eternal_truth_echo.vpcf", PATTACH_ABSORIGIN, tear)
				ParticleManager:SetParticleControl(echo_particle, 1, line_end)
				ParticleManager:SetParticleControl(echo_particle, 2, line_start)
				ParticleManager:SetParticleControl(echo_particle, 3, line_end)
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
	echoDamage(keys.caster, keys.damage_dealt, DAMAGE_TYPE_PHYSICAL)
end