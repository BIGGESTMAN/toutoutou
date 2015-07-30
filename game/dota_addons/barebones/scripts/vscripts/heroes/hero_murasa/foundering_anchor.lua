LinkLuaModifier("modifier_resists_reduction", "heroes/hero_murasa/modifier_resists_reduction.lua", LUA_MODIFIER_MOTION_NONE )

function throwAnchor(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)

	-- Spend a charge
	caster.anchor_charges = caster.anchor_charges - 1

	-- Create the anchor unit
	local anchor = CreateUnitByName("anchor", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, anchor, keys.anchor_modifier, {})
	anchor.units_hit = {}

	-- if not caster.anchors then caster.anchors = {} end
	-- caster.anchors[anchor] = true

	-- Various movement variable
	local target_point = keys.target_points[1]
	local anchor_location = anchor:GetAbsOrigin()
	local direction = (target_point - anchor_location):Normalized()

	local dummy_speed = speed * 0.03
	local arrival_distance = 25
	local height_offset = Vector(0,0,75)
	local drag_distance = 50

	anchor:SetForwardVector(direction)
	anchor:SetAbsOrigin(anchor:GetAbsOrigin() + height_offset)

	Timers:CreateTimer(0, function()
		local caster_ghosted = caster:HasModifier("modifier_ghost")
		local damage_type = DAMAGE_TYPE_PHYSICAL
		if caster_ghosted then damage_type = DAMAGE_TYPE_MAGICAL end

		anchor_location = anchor:GetAbsOrigin()
		local distance = (target_point - anchor_location):Length2D()
		if distance > arrival_distance then
			-- Move projectile
			anchor:SetAbsOrigin(anchor_location + direction * dummy_speed)

			-- Check for units hit
			local team = caster:GetTeamNumber()
			local origin = anchor_location
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER
			local radius = ability:GetLevelSpecialValueFor("drag_radius", ability_level)

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
			local damage = ability:GetLevelSpecialValueFor("drag_damage", ability_level)

			for k,unit in pairs(targets) do
				if not unit:HasModifier(keys.drag_modifier) then
					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					if not caster_ghosted then
						ability:ApplyDataDrivenModifier(anchor, unit, keys.drag_modifier, {})
						anchor.units_hit[unit] = true
					end
				end
			end

			if not caster_ghosted then
				for unit,v in pairs(anchor.units_hit) do
					local anchor_direction = anchor:GetForwardVector()
					local direction_towards_anchor = (anchor:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized()
					local angle = anchor_direction:Dot(direction_towards_anchor)

					local target_distance = (unit:GetAbsOrigin() - anchor:GetAbsOrigin()):Length2D()

					if target_distance > drag_distance and angle > 0 then
						local target_direction = (unit:GetAbsOrigin() - anchor:GetAbsOrigin()):Normalized()
						unit:SetAbsOrigin(anchor:GetAbsOrigin() + drag_distance * target_direction)
					end
				end
			else
				-- Release dragged units
				for unit,v in pairs(anchor.units_hit) do
					unit:RemoveModifierByName(keys.drag_modifier)
					FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
				end
				anchor.units_hit = {}
			end

			return 0.03
		else
			anchor:SetAbsOrigin(target_point + height_offset)
			anchor:SetForwardVector((anchor:GetForwardVector() + Vector(0,0,-1)):Normalized()) -- Goofy shit to make anchor look stuck in the ground

			-- Release dragged units
			for unit,v in pairs(anchor.units_hit) do
				unit:RemoveModifierByName(keys.drag_modifier)
				FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
			end

			-- Root and damage in impact area
			local team = caster:GetTeamNumber()
			local origin = anchor_location
			local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
			local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
			local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
			local iOrder = FIND_ANY_ORDER
			local radius = ability:GetLevelSpecialValueFor("destination_radius", ability_level)

			local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
			local damage = ability:GetLevelSpecialValueFor("destination_damage", ability_level)

			for k,unit in pairs(targets) do
				ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
				ability:ApplyDataDrivenModifier(anchor, unit, keys.root_modifier, {})
			end

			Timers:CreateTimer(ability:GetLevelSpecialValueFor("anchor_duration", ability_level), function()
				-- caster.anchors[anchor] = nil
				anchor:RemoveSelf()
			end)
		end
	end)

	local particle = ParticleManager:CreateParticle(keys.aura_particle, PATTACH_ABSORIGIN_FOLLOW, anchor)
	ParticleManager:SetParticleControl(particle, 1, Vector(ability:GetLevelSpecialValueFor("resists_reduction_radius", ability_level),0,0))
end

function resistsReductionModifierCreated(keys)
	keys.target:AddNewModifier(keys.caster, keys.ability, "modifier_resists_reduction", {})
end

function resistsReductionModifierDestroyed(keys)
	keys.target:RemoveModifierByName("modifier_resists_reduction")
end

function updateCharges(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local max_charges = ability:GetLevelSpecialValueFor("max_charges", ability_level)
	local charge_restore_time = ability:GetLevelSpecialValueFor("charge_restore_time", ability_level)

	if not caster.anchor_charges then caster.anchor_charges = 0 end
	local remaining_time_for_charge = (1 - caster.anchor_charges % 1) * charge_restore_time

	if caster.anchor_charges < max_charges then
		caster.anchor_charges = caster.anchor_charges + ability:GetLevelSpecialValueFor("update_interval", ability_level) / charge_restore_time
	else
		caster.anchor_charges = max_charges
	end

	if caster.anchor_charges >= 1 then
		ability:ApplyDataDrivenModifier(caster, caster, keys.charges_modifier, {})
		local old_stack_count = caster:GetModifierStackCount(keys.charges_modifier, caster)
		local new_stack_count = math.floor(caster.anchor_charges)
		caster:SetModifierStackCount(keys.charges_modifier, caster, new_stack_count)
		if new_stack_count ~= old_stack_count and new_stack_count ~= max_charges then
			caster:FindModifierByName(keys.charges_modifier):SetDuration(remaining_time_for_charge, true)
		end
	else
		caster:RemoveModifierByName(keys.charges_modifier)
		if ability:IsCooldownReady() then
			ability:StartCooldown(remaining_time_for_charge)
		end
	end
end

function checkRestoreCharges(keys)
	local ability = keys.ability
	local ability_level = ability:GetLevel()

	if ability_level == 1 then caster.anchor_charges = ability:GetLevelSpecialValueFor("max_charges", ability_level) end
end

function checkGhostForm(keys)
	local caster = keys.caster
	local ability = keys.ability
	local anchor = keys.target

	if caster:HasModifier("modifier_ghost") then
		ability:ApplyDataDrivenModifier(caster, anchor, "modifier_anchor_ghost", {})
	else
		anchor:RemoveModifierByName("modifier_anchor_ghost")
	end
end

function dealGhostDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel()
	local anchor = keys.target

	local team = caster:GetTeamNumber()
	local origin = anchor:GetAbsOrigin()
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER
	local radius = ability:GetLevelSpecialValueFor("ghost_damage_radius", ability_level)

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
	local damage = ability:GetLevelSpecialValueFor("ghost_form_damage", ability_level)
	local damage_type = DAMAGE_TYPE_MAGICAL

	for k,unit in pairs(targets) do
		ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		local particle = ParticleManager:CreateParticle("particles/foundering_anchor_ghost_damage.vpcf", PATTACH_POINT_FOLLOW, unit)
		ParticleManager:SetParticleControlEnt(particle, 0, anchor, PATTACH_POINT_FOLLOW, "attach_hitloc", origin, true) 
		ParticleManager:SetParticleControlEnt(particle, 1, unit, PATTACH_POINT_FOLLOW, "attach_hitloc", unit:GetAbsOrigin(), true)
		ParticleManager:ReleaseParticleIndex(particle)
		EmitSoundOn("Hero_Pugna.NetherWard.Attack", anchor)
	end
end