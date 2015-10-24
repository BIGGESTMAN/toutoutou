hanumans_dance = class({})
LinkLuaModifier("modifier_dance_recastable", "heroes/hero_byakuren/modifier_dance_recastable.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_dancing", "heroes/hero_byakuren/modifier_dancing.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_hanumans_dance", "heroes/hero_byakuren/modifier_hanumans_dance.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_hanumans_dance_as_bonus", "heroes/hero_byakuren/modifier_hanumans_dance_as_bonus.lua", LUA_MODIFIER_MOTION_NONE )


function hanumans_dance:OnSpellStart()
	if IsServer() then
		require "libraries/animations"
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		local ability = self
		local ability_level = ability:GetLevel() - 1

		ability:StartCooldown(caster:GetSecondsPerAttack())

		local prior_slashes = 0
		if caster:HasModifier("modifier_dance_recastable") then
			prior_slashes = caster:GetModifierStackCount("modifier_dance_recastable", caster)
		end
		caster:AddNewModifier(caster, ability, "modifier_dancing", {target = target:GetEntityIndex(), prior_slashes = prior_slashes})

		-- Spend a charge, unless charges modifier has expired during cast animation
		if caster:HasModifier("modifier_vajrapanis_charges") then
			local charge_modifier = caster:FindModifierByName("modifier_vajrapanis_charges")
			if charge_modifier:GetStackCount() > 1 then
				charge_modifier:DecrementStackCount()
			else
				charge_modifier:Destroy()
			end
		end

		caster:AddNewModifier(caster, ability, "modifier_dance_recastable", {duration = ability:GetLevelSpecialValueFor("recast_time", ability_level)})
		local recast_modifier = caster:FindModifierByName("modifier_dance_recastable")
		recast_modifier:IncrementStackCount()

		-- Max slashes per chain functionality, not currently used
		-- if recast_modifier:GetStackCount() < ability:GetLevelSpecialValueFor("max_slashes", ability_level) - 1 then
		-- 	recast_modifier:IncrementStackCount()
		-- else
		-- 	recast_modifier:Destroy()
		-- end

		-- Ability cooldown functionality, not currently used
		-- if recast_modifier:GetStackCount() == 1 then
		-- 	recast_modifier.initial_cast_time = GameRules:GetGameTime()
		-- end
	end
end

function hanumans_dance:GetIntrinsicModifierName()
	return "modifier_hanumans_dance"
end

function hanumans_dance:GetCastAnimation()
	return ACT_DOTA_ATTACK
end

function hanumans_dance:GetCooldown( nLevel )
	return self:GetCaster():GetSecondsPerAttack()
end

function hanumans_dance:GetCastRange( vLocation, hTarget )
	if hTarget ~= nil and hTarget:HasModifier("modifier_light_fragment") then
		local virudhakas_ability = self:GetCaster():FindAbilityByName("virudhakas_sword")
		local level = virudhakas_ability:GetLevel() - 1
		return virudhakas_ability:GetLevelSpecialValueFor("hanumans_dash_range", level)
	else
		return self:GetSpecialValueFor("cast_range")
	end
end