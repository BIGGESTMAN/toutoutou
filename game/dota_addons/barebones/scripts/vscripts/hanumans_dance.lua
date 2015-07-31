hanumans_dance = class({})
LinkLuaModifier("modifier_dance_recastable", "heroes/hero_byakuren/modifier_dance_recastable.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_dancing", "heroes/hero_byakuren/modifier_dancing.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_hanumans_dance", "heroes/hero_byakuren/modifier_hanumans_dance.lua", LUA_MODIFIER_MOTION_NONE )

function hanumans_dance:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		local ability = self
		local ability_level = ability:GetLevel() - 1

		ability:EndCooldown()
		ability:StartCooldown(caster:GetSecondsPerAttack())

		caster:AddNewModifier(caster, ability, "modifier_dancing", {er_what = "pls", dancing_target = target, errrr_um = "game is hard"})
		local modifier = caster:FindModifierByName("modifier_dancing")
		modifier.target = target
		modifier.prior_slashes = 0
		if caster:HasModifier("modifier_dance_recastable") then
			modifier.prior_slashes = caster:GetModifierStackCount("modifier_dance_recastable", caster)
		end

		if not caster:HasModifier("modifier_dance_recastable") then
			local charge_modifier = caster:FindModifierByName("modifier_vajrapanis_charges")
			if charge_modifier:GetStackCount() > 1 then
				charge_modifier:DecrementStackCount()
			else
				charge_modifier:Destroy()
			end
		end

		caster:AddNewModifier(caster, ability, "modifier_dance_recastable", {duration = ability:GetLevelSpecialValueFor("recast_time", ability_level)})
		local recast_modifier = caster:FindModifierByName("modifier_dance_recastable")
		if recast_modifier:GetStackCount() < ability:GetLevelSpecialValueFor("max_slashes", ability_level) - 1 then
			recast_modifier:IncrementStackCount()
		else
			recast_modifier:Destroy()
		end

		if recast_modifier:GetStackCount() == 1 then
			recast_modifier.initial_cast_time = GameRules:GetGameTime()
		end
	end
end

function hanumans_dance:GetIntrinsicModifierName()
	return "modifier_hanumans_dance"
end