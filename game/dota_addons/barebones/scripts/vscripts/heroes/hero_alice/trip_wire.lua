require "libraries/util"
require "heroes/hero_alice/dolls"

function createWire(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	
	if not caster.wires then caster.wires = {} end

	-- Make sure identical wires aren't created
	local identical_wire = false
	for k,existing_wire in pairs(caster.wires) do
		if existing_wire[2] == target and existing_wire[1] == caster then
			identical_wire = true
			break
		end
	end

	if not identical_wire then
		local location = (target:GetAbsOrigin() + caster:GetAbsOrigin()) / 2 + Vector(0,0,50)
		local wire_unit = CreateUnitByName("npc_dota_juggernaut_healing_ward", location, false, caster, caster, caster:GetTeamNumber())
		ability:ApplyDataDrivenModifier(caster, wire_unit, keys.wire_unit_modifier, {})
		wire_unit.stored_dolls = {}

		-- Wire is table with three values--each of its two attachee units and the unit for itself
		local wire = {keys.caster, keys.target, wire_unit}
		caster.wires[wire_unit] = wire

		wire_unit.ally_particle = ParticleManager:CreateParticleForTeam("particles/alice/trip_wire.vpcf", PATTACH_POINT_FOLLOW, wire[1], caster:GetTeamNumber())

		wire[3]:SetOriginalModel("models/development/invisiblebox.vmdl")
		wire[3]:SetModelScale(10) -- to make wire unit easier to click on
		ability:ApplyDataDrivenModifier(caster, wire[3], "modifier_kill", {duration = ability:GetLevelSpecialValueFor("duration", ability_level)})

		caster.last_wire = wire
		-- Enable attaching-secondary-target ability
		local main_ability_name	= ability:GetAbilityName()
		local sub_ability_name	= keys.attach_ability_name
		caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
		ability:ApplyDataDrivenModifier(caster, caster, keys.attach_window_modifier, {})

		ability:ApplyDataDrivenModifier(caster, caster, keys.caster_modifier, {})
	end
end

function updateWire(keys)
	if not keys.target:IsNull() and keys.caster.wires[keys.target] then -- as usual, no idea how this is possible, but whatever
		local caster = keys.caster
		local ability = keys.ability
		local ability_level = ability:GetLevel() - 1
		local wire = caster.wires[keys.target]
		local target1 = wire[1]
		local target2 = wire[2]
		local range = nil

		-- I fucking despise trees
		local tree_cut_down = false
		local target1_is_tree = target1.IsStanding
		local target2_is_tree = target2.IsStanding
		if (target1_is_tree and not target1:IsStanding()) or (target2_is_tree and not target2:IsStanding()) then
			tree_cut_down = true
		end

		if not target1:IsNull() and not target2:IsNull() then -- make sure both wire attachees still exist
			range = (target2:GetAbsOrigin() - target1:GetAbsOrigin()):Length2D()
		end
		if range and range <= ability:GetLevelSpecialValueFor("max_length", ability_level) and target1:IsAlive() and target2:IsAlive() and not tree_cut_down then
			-- Update wire unit position
			wire[3]:SetAbsOrigin((target1:GetAbsOrigin() + target2:GetAbsOrigin()) / 2 + Vector(0,0,50))

			-- Particle shit
			-- Check visibility of wire to enemy team
			local dummy_enemy = CreateUnitByName("npc_dummy_unit", Vector(0,0,0), false, caster, caster, caster:GetOpposingTeamNumber())
			local visibleToEnemies = dummy_enemy:CanEntityBeSeenByMyTeam(wire[3])
			dummy_enemy:RemoveSelf()

			-- Update ally particle
			ParticleManager:SetParticleControl(wire[3].ally_particle,0,Vector(target1:GetAbsOrigin().x,target1:GetAbsOrigin().y,target1:GetAbsOrigin().z + target1:GetBoundingMaxs().z ))	
			ParticleManager:SetParticleControl(wire[3].ally_particle,1,Vector(target2:GetAbsOrigin().x,target2:GetAbsOrigin().y,target2:GetAbsOrigin().z + target2:GetBoundingMaxs().z ))

			-- Create/destroy and update enemy particle
			local particle = nil
			if wire[3].enemy_particle then
				if not visibleToEnemies then
					ParticleManager:DestroyParticle(wire[3].enemy_particle, false)
					wire[3].enemy_particle = nil
				else
					ParticleManager:SetParticleControl(wire[3].enemy_particle,0,Vector(target1:GetAbsOrigin().x,target1:GetAbsOrigin().y,target1:GetAbsOrigin().z + target1:GetBoundingMaxs().z ))	
					ParticleManager:SetParticleControl(wire[3].enemy_particle,1,Vector(target2:GetAbsOrigin().x,target2:GetAbsOrigin().y,target2:GetAbsOrigin().z + target2:GetBoundingMaxs().z ))
				end
			elseif visibleToEnemies then
				wire[3].enemy_particle = ParticleManager:CreateParticleForTeam("particles/alice/trip_wire.vpcf", PATTACH_POINT_FOLLOW, wire[1], caster:GetOpposingTeamNumber())
				ParticleManager:SetParticleControl(wire[3].enemy_particle,0,Vector(target1:GetAbsOrigin().x,target1:GetAbsOrigin().y,target1:GetAbsOrigin().z + target1:GetBoundingMaxs().z ))	
				ParticleManager:SetParticleControl(wire[3].enemy_particle,1,Vector(target2:GetAbsOrigin().x,target2:GetAbsOrigin().y,target2:GetAbsOrigin().z + target2:GetBoundingMaxs().z ))
			end

			-- If dolls are stored, update indicator particle
			if not wire[3].indicator_particle then
				wire[3].indicator_particle = ParticleManager:CreateParticleForTeam("particles/alice/trip_wire_dolls_stored_indicator.vpcf", PATTACH_OVERHEAD_FOLLOW, wire[3], caster:GetTeamNumber())
			end
			ParticleManager:SetParticleControl(wire[3].indicator_particle, 1, Vector(0, #wire[3].stored_dolls, 0))


			-- Check for enemy units in wire's path
			local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
			local direction = (target2:GetAbsOrigin() - target1:GetAbsOrigin()):Normalized()

			local hit_units = unitsInLine(caster, target1:GetAbsOrigin(), range, radius, direction)

			if #hit_units > 0 then
				wire_triggered = false -- Make sure attaching to an enemy doesn't instantly break wire
				for k,unit in pairs(hit_units) do
					if unit ~= target1 and unit ~= target2 then
						wire_triggered = true
					end
				end

				if wire_triggered then
					for k,unit in pairs(hit_units) do
						ApplyDamage({victim = unit, attacker = caster, damage = ability:GetLevelSpecialValueFor("damage", ability_level), damage_type = DAMAGE_TYPE_MAGICAL})
						ability:ApplyDataDrivenModifier(caster, unit, "modifier_trip_wire_root", {})
					end

					local wire_location = wire[3]:GetAbsOrigin()
					local little_legion_ability = caster:FindAbilityByName("little_legion")
					for i=1,#wire[3].stored_dolls do
						Timers:CreateTimer(i * ability:GetLevelSpecialValueFor("delay_between_doll_spawns", ability_level), function()
							for i=1, #hit_units do -- Make sure dolls aren't spawning and going after units that're already dead
								if not hit_units[i]:IsAlive() then table.remove(hit_units, i) end
							end
							spawnDoll(little_legion_ability, hit_units[RandomInt(1, #hit_units)], caster, wire_location)
						end)
					end

					destroyWire(wire, caster)
				end
			end
		else
			destroyWire(wire, caster)
		end
	end
end

function attach(keys)
	local caster = keys.caster
	local target = keys.target
	local wire_distance = (caster.last_wire[2]:GetAbsOrigin() - target:GetAbsOrigin()):Length2D()
	local wire_ability = caster:FindAbilityByName("trip_wire")

	-- Make sure identical wires aren't created
	local identical_wire = false
	for k,existing_wire in pairs(caster.wires) do
		if (existing_wire[2] == caster.last_wire[2] and existing_wire[1] == target) or (existing_wire[1] == caster.last_wire[2] and existing_wire[2] == target) then
			identical_wire = true
			break
		end
	end

	if caster.last_wire[2] ~= target and wire_distance <= wire_ability:GetLevelSpecialValueFor("max_length", wire_ability:GetLevel() - 1) and not identical_wire then
		caster.last_wire[1] = target
		local main_ability_name	= keys.main_ability_name
		local sub_ability_name	= keys.ability:GetAbilityName()
		caster:SwapAbilities(main_ability_name, sub_ability_name, true, false)
		caster:RemoveModifierByName("modifier_trip_wire_attach_window")
	end
end

function onWireDeath(keys)
	destroyWire(keys.caster.wires[keys.target], keys.caster)
end

function destroyWire(wire, caster)
	-- Clean out particles
	ParticleManager:DestroyParticle(wire[3].ally_particle, false)
	if wire[3].enemy_particle then ParticleManager:DestroyParticle(wire[3].enemy_particle, false) end
	if wire[3].indicator_particle then ParticleManager:DestroyParticle(wire[3].indicator_particle, false) end

	-- Triggered particle
	local trigger_particle = ParticleManager:CreateParticle("particles/alice/trip_wire_trigger.vpcf", PATTACH_POINT_FOLLOW, wire[1])
	ParticleManager:SetParticleControl(trigger_particle,0,Vector(wire[1]:GetAbsOrigin().x,wire[1]:GetAbsOrigin().y,wire[1]:GetAbsOrigin().z + wire[1]:GetBoundingMaxs().z ))	
	ParticleManager:SetParticleControl(trigger_particle,1,Vector(wire[2]:GetAbsOrigin().x,wire[2]:GetAbsOrigin().y,wire[2]:GetAbsOrigin().z + wire[2]:GetBoundingMaxs().z ))

	caster.wires[wire[3]] = nil
	if caster:FindAbilityByName("trip_wire"):IsHidden() and wire == caster.last_wire then
		caster:RemoveModifierByName("modifier_trip_wire_attach_window")
	end
	if not wire[3]:IsNull() then wire[3]:RemoveSelf() end
end

function removeAttachAbility(keys)
	local caster = keys.caster
	if caster:FindAbilityByName("trip_wire"):IsHidden() then
		caster:SwapAbilities("trip_wire", "trip_wire_attach", true, false)
	end
end

function upgradeAttachAbility(keys)
	local main_ability = keys.caster:FindAbilityByName(keys.ability:GetAbilityName())
	local sub_ability = keys.caster:FindAbilityByName(keys.attach_ability)
	sub_ability:SetLevel(main_ability:GetLevel())
end