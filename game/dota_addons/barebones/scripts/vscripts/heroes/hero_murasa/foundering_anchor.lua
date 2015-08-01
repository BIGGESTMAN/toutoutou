LinkLuaModifier("modifier_resists_reduction", "heroes/hero_murasa/modifier_resists_reduction.lua", LUA_MODIFIER_MOTION_NONE )

require "heroes/hero_murasa/anchors"

function throwAnchor(keys)
	local caster = keys.caster
	local ability = keys.ability

	-- Spend a charge
	caster.anchor_charges = caster.anchor_charges - 1

	anchor(caster, ability, keys.target_points[1])

	EmitSoundOn("Touhou.Anchor_Cast", caster)
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
		ability:ApplyDataDrivenModifier(caster, caster, keys.anchor_charges_modifier, {})
		local old_stack_count = caster:GetModifierStackCount(keys.anchor_charges_modifier, caster)
		local new_stack_count = math.floor(caster.anchor_charges)
		caster:SetModifierStackCount(keys.anchor_charges_modifier, caster, new_stack_count)
		if new_stack_count ~= old_stack_count and new_stack_count ~= max_charges and caster:IsAlive() then
			caster:FindModifierByName(keys.anchor_charges_modifier):SetDuration(remaining_time_for_charge, true)
		end
	else
		caster:RemoveModifierByName(keys.anchor_charges_modifier)
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

function upgradeDraggingAnchor(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel()

	if ability_level == 1 then
		caster:FindAbilityByName("dragging_anchor"):SetLevel(ability_level)
	end
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