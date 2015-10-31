require "libraries/util"

-- LinkLuaModifier("modifier_dummy", "modifier_dummy.lua", LUA_MODIFIER_MOTION_NONE )

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local damage = ability:GetSpecialValueFor("damage")
	local damage_type = ability:GetAbilityDamageType()
	local blade_range = ability:GetSpecialValueFor("blade_range")
	local blade_radius = ability:GetSpecialValueFor("blade_radius")
	local swing_duration = ability:GetSpecialValueFor("duration")
	local illusion_damage = damage * ability:GetSpecialValueFor("illusion_damage_percent") / 100
	local update_interval = ability:GetSpecialValueFor("update_interval")

	local swing_angle = 180
	local illusion_search_radius = 20100

	local time_elapsed = 0

	-- Find illusions
	local casters = {}
	table.insert(casters, caster)
	local team = caster:GetTeamNumber()
	local origin = caster:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local units = FindUnitsInRadius(team, origin, nil, illusion_search_radius, iTeam, iType, iFlag, iOrder, false)
	for k,unit in pairs(units) do
		if unit:IsIllusion() and unit:GetPlayerID() == caster:GetPlayerID() and unit:IsAlive() and not unit:IsStunned() and not unit:IsSilenced() then
			table.insert(casters, unit)
		end
	end

	for k,unit in pairs(casters) do
		unit:Stop()
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_lavatein_casting", {})

		unit.lavatein_overall_direction = (target_point - unit:GetAbsOrigin()):Normalized()
		unit.lavatein_overall_direction.z = 0
		unit.lavatein_units_hit = {}

		unit:SetForwardVector(unit.lavatein_overall_direction)

		-- local particle_dummy = CreateUnitByName("npc_dummy_unit", unit:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
		-- particle_dummy:AddNewModifier(unit, ability, "modifier_dummy", {})
		local particle = ParticleManager:CreateParticle("particles/flandre/lavatein/slash.vpcf", PATTACH_ABSORIGIN, unit)
		-- local initial_sword_location = RotatePosition(Vector(0,0,0), QAngle(0,swing_angle / 2,0), unit.lavatein_overall_direction) * 800
		-- DebugDrawCircle(initial_sword_location + unit:GetAbsOrigin(), Vector(255,0,0), 1, blade_radius, true, 2)
		-- print(initial_sword_location)
		-- ParticleManager:SetParticleControl(particle, 1, initial_sword_location)
	end

	Timers:CreateTimer(0, function()
		if time_elapsed < swing_duration then
			for k,unit in pairs(casters) do
				local direction = RotatePosition(Vector(0,0,0), QAngle(0,swing_angle - swing_angle * time_elapsed / swing_duration - (swing_angle / 2),0), unit.lavatein_overall_direction)
				-- DebugDrawCircle(direction * blade_range + unit:GetAbsOrigin(), Vector(255,0,0), 1, blade_radius, true, 2)
				local targets = unitsInLine(unit, unit:GetAbsOrigin(), blade_range, blade_radius, direction, true)
				for k,target in pairs(targets) do
					if not unit.lavatein_units_hit[target] then
						if unit:IsIllusion() then
							ApplyDamage({victim = target, attacker = unit, damage = illusion_damage, damage_type = damage_type})
						else
							ApplyDamage({victim = target, attacker = unit, damage = damage, damage_type = damage_type})
						end
						unit.lavatein_units_hit[target] = true
					end
				end
			end
			time_elapsed = time_elapsed + update_interval
			return update_interval
		else
			for k,unit in pairs(casters) do
				unit.lavatein_overall_direction = nil
				unit.lavatein_units_hit = nil
			end
		end
	end)
end