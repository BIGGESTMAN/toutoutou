require "personas"

function SpellCast(keys)
	local caster = keys.caster
	local ability = CreateDummyAbility(caster, keys.ability)
	local target_point = keys.target_points[1]

	local range = ability:GetSpecialValueFor("range")
	local radius = ability:GetSpecialValueFor("radius")
	local base_damage = ability:GetSpecialValueFor("damage")
	local magic_multiplier = ability:GetSpecialValueFor("damage_magic_multiplier")
	local damage = base_damage + magic_multiplier * caster.activePersona.attributes["mag"]
	local damage_type = DAMAGE_TYPE_PHYSICAL
	local persona_damage_type = "wind"
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local speed = ability:GetSpecialValueFor("speed") * update_interval

	local tornado = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, tornado, "modifier_spiral_force_dummy", {})

	local particle = ParticleManager:CreateParticle("particles/spells/magic_spiral_force.vpcf", PATTACH_ABSORIGIN_FOLLOW, tornado)
	ParticleManager:SetParticleControlEnt(particle, 0, tornado, PATTACH_ABSORIGIN_FOLLOW, "attach_hitloc", tornado:GetAbsOrigin(), true)

	local total_duration = 2
	local turn_speed = 300 * update_interval
	local reverse_interval = 0.6
	local reverses_made = 0
	local turning_pause_time_after_reverse = 0.2
	local turning_paused_time = turning_pause_time_after_reverse

	local tornado_location = tornado:GetAbsOrigin()
	local direction = (target_point - tornado_location):Normalized()
	direction = RotatePosition(Vector(0,0,0), QAngle(0,45,0), direction) -- Offset initial angle to tornado doesn't lean to the right
	direction.z = 0

	local time_elapsed = 0
	local units_hit = {}
	DebugDrawCircle(tornado_location, Vector(180,40,40), 0.1, range, true, total_duration)

	Timers:CreateTimer(0, function()
		if not tornado:IsNull() then
			tornado_location = tornado:GetAbsOrigin()
			if time_elapsed < total_duration then
				-- Turn & move projectile
				if time_elapsed >= reverse_interval * (reverses_made + 1) + turning_pause_time_after_reverse * reverses_made then
					-- Reverse turn direction
					reverses_made = reverses_made + 1
					turning_paused_time = turning_pause_time_after_reverse
				end
				if turning_paused_time <= 0 then
					local turn_angle = turn_speed * ((reverses_made % 2) * 2 - 1)
					direction = RotatePosition(Vector(0,0,0), QAngle(0,turn_angle,0), direction)
				else
					turning_paused_time = turning_paused_time - update_interval
				end
				tornado:SetAbsOrigin(tornado_location + direction * speed)
				time_elapsed = time_elapsed + update_interval

				-- Check for units hit
				local team = caster:GetTeamNumber()
				local origin = tornado:GetAbsOrigin()
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_ANY_ORDER
				-- DebugDrawCircle(origin, Vector(180,40,40), 0.1, radius, true, 0.2)

				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

				for k,unit in pairs(targets) do
					if not units_hit[unit] then
						ApplyCustomDamage(unit, caster, damage, damage_type, persona_damage_type)
						unit:SetForwardVector(unit:GetForwardVector() * -1)
						units_hit[unit] = true
					end
				end
				return update_interval
			else
				tornado:RemoveSelf()
			end
		end
	end)
end