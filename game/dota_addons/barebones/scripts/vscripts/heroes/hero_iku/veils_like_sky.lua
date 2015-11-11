LinkLuaModifier("modifier_veils_like_sky_windburn", "heroes/hero_iku/modifier_veils_like_sky_windburn.lua", LUA_MODIFIER_MOTION_NONE )

function updateMovement(keys)
	local caster = keys.caster
	local ability = keys.ability

	local deactivate_time = ability:GetSpecialValueFor("stationary_deactivate_time")
	local update_interval = ability:GetSpecialValueFor("update_interval")

	currentLocation = caster:GetAbsOrigin()
	if not caster.veils_like_sky_previous_location then caster.veils_like_sky_previous_location = currentLocation end
	local moved = (caster.veils_like_sky_previous_location - currentLocation):Length2D() > 0
	caster.veils_like_sky_previous_location = currentLocation

	if not moved then
		if not caster.veils_time_since_moved then
			caster.veils_time_since_moved = 0
		elseif caster.veils_time_since_moved == update_interval and caster:HasModifier("modifier_veils_like_sky_evasion") then -- Give one frame's leeway to account for movement skipping frames sometimes, so modifier duration doesn't flicker
			caster:FindModifierByName("modifier_veils_like_sky_evasion"):SetDuration(deactivate_time, true)
		end

		caster.veils_time_since_moved = caster.veils_time_since_moved + update_interval
		if caster.veils_time_since_moved >= deactivate_time then
			caster:RemoveModifierByName("modifier_veils_like_sky_evasion")
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_veils_like_sky_evasion_disabled", {})
		end
	else
		caster.veils_time_since_moved = nil
		local evasion_modifier = caster:FindModifierByName("modifier_veils_like_sky_evasion")
		if caster:HasModifier("modifier_veils_like_sky_evasion") then
			caster:RemoveModifierByName("modifier_veils_like_sky_evasion")
			ability:ApplyDataDrivenModifier(caster, caster, "modifier_veils_like_sky_evasion", {})
		end
	end
end

function abilityExecuted(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_executed = keys.event_ability

	if not ability_executed:IsItem() then
		caster:RemoveModifierByName("modifier_veils_like_sky_evasion")
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_veils_like_sky_evasion_disabled", {})
	end
end

function evasionDisabledExpiration(keys)
	local caster = keys.caster
	local ability = keys.ability

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_veils_like_sky_evasion", {})
end

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	if not caster:HasModifier("modifier_elekiter_dragon_palace_active") then
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_veils_like_sky_magic_dodge", {})
	else
		caster:RemoveModifierByName("modifier_elekiter_dragon_palace_active")
		local damage = ability:GetSpecialValueFor("elekiter_damage")
		local damage_type = ability:GetAbilityDamageType()
		local duration = ability:GetSpecialValueFor("elekiter_duration")

		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local radius = ability:GetSpecialValueFor("radius")
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
		DebugDrawCircle(origin, Vector(0,0,255), 1, radius, true, 0.5)

		for k,unit in pairs(targets) do
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_veils_like_sky_windburn_stun", {})
			unit:AddNewModifier(caster, ability, "modifier_veils_like_sky_windburn", {duration = duration})
		end
	end
end

function magicDodgeRemoved(keys)
	local caster = keys.caster
	local ability = keys.ability

	if caster.veils_magic_dodged then
		caster.veils_magic_dodged = false
		local radius = ability:GetSpecialValueFor("radius")
		local damage = ability:GetSpecialValueFor("damage")
		local damage_type = ability:GetAbilityDamageType()

		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
		DebugDrawCircle(origin, Vector(0,0,255), 1, radius, true, 0.5)

		for k,unit in pairs(targets) do
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
			ability:ApplyDataDrivenModifier(caster, unit, "modifier_veils_like_sky_stun", {})
		end
	end
end