LinkLuaModifier("modifier_resists_reduction", "heroes/hero_murasa/modifier_resists_reduction.lua", LUA_MODIFIER_MOTION_NONE )

function throwAnchor(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)

	caster.anchor_charges = caster.anchor_charges - 1

	local anchor = CreateUnitByName("anchor", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, anchor, keys.anchor_modifier, {})

	local target_point = keys.target_points[1]
	local anchor_location = anchor:GetAbsOrigin()
	local direction = (target_point - anchor_location):Normalized()

	local dummy_speed = speed * 0.03
	local arrival_distance = 25
	local height_offset = Vector(0,0,50)
	local drag_distance = 50

	anchor:SetForwardVector(direction)
	anchor:SetAbsOrigin(anchor:GetAbsOrigin() + height_offset)
	anchor.units_hit = {}

	Timers:CreateTimer(0, function()
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
			local damage_type = ability:GetAbilityDamageType()

			for k,unit in pairs(targets) do
				if not unit:HasModifier(keys.drag_modifier) then
					ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
					ability:ApplyDataDrivenModifier(anchor, unit, keys.drag_modifier, {})
					anchor.units_hit[unit] = true
				end
			end

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
			return 0.03
		else
			anchor:SetAbsOrigin(target_point + height_offset * 1.5)
			anchor:SetForwardVector((anchor:GetForwardVector() + Vector(0,0,-1)):Normalized()) -- Goofy shit to make anchor look stuck in the ground

			-- Finish dragging units
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
			local damage_type = ability:GetAbilityDamageType()

			for k,unit in pairs(targets) do
				ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
				ability:ApplyDataDrivenModifier(anchor, unit, keys.root_modifier, {})
			end

			Timers:CreateTimer(ability:GetLevelSpecialValueFor("anchor_duration", ability_level), function()
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
	if caster.anchor_charges < max_charges then
		caster.anchor_charges = caster.anchor_charges + ability:GetLevelSpecialValueFor("update_interval", ability_level) / charge_restore_time
	else
		caster.anchor_charges = max_charges
	end

	if caster.anchor_charges >= 1 then
		ability:ApplyDataDrivenModifier(caster, caster, keys.charges_modifier, {})
		caster:SetModifierStackCount(keys.charges_modifier, caster, math.floor(caster.anchor_charges))
	else
		caster:RemoveModifierByName(keys.charges_modifier)
		if ability:IsCooldownReady() then
			ability:StartCooldown((1 - caster.anchor_charges) * charge_restore_time)
		end
	end
end

function checkRestoreCharges(keys)
	local ability = keys.ability
	local ability_level = ability:GetLevel()

	if ability_level == 1 then caster.anchor_charges = ability:GetLevelSpecialValueFor("max_charges", ability_level) end
end