function indrasThunderCast(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Spend a charge, unless charges modifier has expired during cast animation
	if caster:HasModifier("modifier_vajrapanis_charges") then
		local charge_modifier = caster:FindModifierByName("modifier_vajrapanis_charges")
		if charge_modifier:GetStackCount() > 1 then
			charge_modifier:DecrementStackCount()
		else
			charge_modifier:Destroy()
		end
	end

	--------------------------------------------- Dummy projectile ----------------------------------

	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)

	local dummy_projectile = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_projectile, keys.projectile_modifier, {})

	local target_point = target:GetAbsOrigin()

	local dummy_speed = speed * 0.03
	local arrival_distance = 25
	local total_degrees_rotated = 90
	local bead_count_factor = 120 -- 120 = arbitrary number to make the number of beads reasonable
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

	-- Virudhaka's Sword light fragments interaction -- remove delay
	local delay = ability:GetLevelSpecialValueFor("delay", ability_level)
	if target:HasModifier("modifier_light_fragment") then
		delay = 0.03 -- Wait a frame so dummy can actually finish moving to the target
		target:RemoveModifierByName("modifier_light_fragment")
	end

	Timers:CreateTimer(0, function()
		if not target:IsNull() then target_point = target:GetAbsOrigin() end
		local dummy_location = dummy_projectile:GetAbsOrigin()
		local distance = (target_point - dummy_location):Length2D()
		local direction = (target_point - dummy_location):Normalized()
		if distance > arrival_distance then
			-- Move projectile
			dummy_projectile:SetAbsOrigin(dummy_location + direction * dummy_speed)
			return 0.03
		else
			dummy_projectile:SetAbsOrigin(target_point)

			-- Start vortex particle -- wait a frame so dummy can actually finish moving
			local vortex_particle = nil
			Timers:CreateTimer(0.03, function()
				-- local particles = {"particles/byakuren/indras_thunder_vortex.vpcf", "particles/byakuren/indras_thunder_vortex_alt.vpcf", "particles/byakuren/indras_thunder_vortex_alt2.vpcf"}
				-- local vortex_particle_name = particles[RandomInt(1, #particles)]
				local vortex_particle_name = "particles/byakuren/indras_thunder_vortex_alt2.vpcf"
				vortex_particle = ParticleManager:CreateParticle(vortex_particle_name, PATTACH_ABSORIGIN, dummy_projectile)
				ParticleManager:SetParticleControl(vortex_particle, 1, Vector(radius,0,0))
			end)

			-- Trigger delayed bead activation
			Timers:CreateTimer(delay,function()
				local team = caster:GetTeamNumber()
				local origin = target_point
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_ANY_ORDER

				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
				local damage = ability:GetLevelSpecialValueFor("damage", ability_level)
				local damage_type = ability:GetAbilityDamageType()

				local pull_duration = ability:GetLevelSpecialValueFor("pull_duration", ability_level)
				dummy_projectile.elapsed_time = 0
				local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)

				for k,unit in pairs(targets) do
					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					ability:ApplyDataDrivenModifier(caster, unit, "modifier_pulled", {})
				end

				-- Lightning strike particle and sound
				local lightning_particle = ParticleManager:CreateParticle("particles/byakuren/indras_thunder_lightning.vpcf", PATTACH_ABSORIGIN, dummy_projectile)
				EmitSoundOn("Hero_Zuus.LightningBolt", dummy_projectile)
				for i=3,15 do
					ParticleManager:SetParticleControl(lightning_particle, i, Vector(radius * .8, 0, 0))
				end

				-- End vortex particle
				if delay > 0.03 then
					ParticleManager:DestroyParticle(vortex_particle, false)
				end

				-- Spin/vacuum hit units
				Timers:CreateTimer(0, function()
					if dummy_projectile.elapsed_time < pull_duration then
						for k,unit in pairs(targets) do
							local spin_angle = total_degrees_rotated * (update_interval / pull_duration) * -1 -- inverted so it matches the bead rotation because i'm great
							unit:SetAbsOrigin(RotatePosition(target_point, QAngle(0,spin_angle,0), unit:GetAbsOrigin()))
							local vacuum_center_distance = (target_point - unit:GetAbsOrigin()):Length2D()
							local vacuum_center_direction = (target_point - unit:GetAbsOrigin()):Normalized()
							-- overcomplicated shit to keep units moving at a constant rate towards the center, probably didn't need to implement it this way but oh well
							unit:SetAbsOrigin(unit:GetAbsOrigin() + vacuum_center_direction * vacuum_center_distance * (dummy_projectile.elapsed_time / pull_duration))
						end
						dummy_projectile.elapsed_time = dummy_projectile.elapsed_time + update_interval
						return update_interval
					else
						dummy_projectile:RemoveSelf()
						for k,bead in pairs(dummy_projectile.beads) do
							bead:RemoveSelf()
						end

						for k,unit in pairs(targets) do
							unit:RemoveModifierByName(keys.pull_modifier)
							FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
						end
					end
				end)
			end)
		end
	end)

	--------------------------------------------- Beads ---------------------------------------------
	local beads = math.ceil(2 * math.pi * radius / bead_count_factor)
	local unit_name = "npc_dummy_unit"

	-- Initialize the table to keep track of all beads
	dummy_projectile.beads = {}

	local particle = "particles/byakuren/bead_possibility_3.vpcf"
	for i=1,beads do
		local unit = CreateUnitByName(unit_name, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())
		local particle = ParticleManager:CreateParticle(particle, PATTACH_ABSORIGIN, unit)
		ParticleManager:SetParticleControlEnt(particle, 0, unit, PATTACH_ABSORIGIN, "attach_origin", unit:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(particle) -- no idea if this line is necessary

		ability:ApplyDataDrivenModifier(caster, unit, keys.bead_modifier, {})
		
		-- Add the spawned unit to the table
		table.insert(dummy_projectile.beads, unit)
	end
	
	dummy_projectile.beads_angle = 0
end

-- Movement logic for each bead
function updateBeads( event )
	local frozen = false
	local caster = event.caster
	local dummy_projectile = event.target
	local dummy_location = dummy_projectile:GetAbsOrigin()
	local ability = event.ability
	local ability_level = ability:GetLevel() - 1
	local vertical_distance_offset = 80
	local rotation_time = 1.5
	local number_of_beads = #dummy_projectile.beads

	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
	if dummy_projectile.elapsed_time then
		local percent_contracted = dummy_projectile.elapsed_time / ability:GetLevelSpecialValueFor("pull_duration", ability_level)
		radius = radius * (1 - percent_contracted)
	end

	local rotation_point = dummy_location + Vector(0,0,1) * vertical_distance_offset

	-- Make beads spin
	dummy_projectile.beads_angle = dummy_projectile.beads_angle + (360 / rotation_time) * ability:GetLevelSpecialValueFor("update_interval", ability_level)

	local overallAngleInRadians = 0
	if not frozen then
		overallAngleInRadians = dummy_projectile.beads_angle * math.pi / 180
	end
	local prototype_target_point = rotation_point + Vector(math.sin(overallAngleInRadians), math.cos(overallAngleInRadians), 0) * radius

	for bead_number=1, number_of_beads do
		local angle = (360 / number_of_beads) * (bead_number - 1)
		local target_point = RotatePosition(rotation_point, QAngle(0,angle,0), prototype_target_point)
		local bead = dummy_projectile.beads[bead_number]
		if not bead:IsNull() then bead:SetAbsOrigin(target_point) end -- I still don't understand why this check is necessary, but whatever
	end
end

function updateAbilityActivated(keys)
	if keys.caster:HasModifier("modifier_vajrapanis_charges") then
		keys.ability:SetActivated(true)
	else
		keys.ability:SetActivated(false)
	end
end