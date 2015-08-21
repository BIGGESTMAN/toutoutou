vajrapanis_incantation_channel = class({})
LinkLuaModifier("modifier_vajrapanis_charges", "heroes/hero_byakuren/modifier_vajrapanis_charges.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_incantation_channeling", "heroes/hero_byakuren/modifier_incantation_channeling.lua", LUA_MODIFIER_MOTION_NONE )

function vajrapanis_incantation_channel:OnSpellStart()
	if IsServer() then
		require("libraries/animations")
		local caster = self:GetCaster()

		local duration = self:GetChannelTime()
		caster:AddNewModifier(caster, self, "modifier_incantation_channeling", {duration = duration * 2}) -- 2 = arbitrary number to make sure it doesn't fall off before the next charge channel can begin

		-- -- Animation nonsense
		if not caster:HasModifier("modifier_incantation_channeling") then
			local animation_properties = {duration = 17 / 30, activity=ACT_DOTA_CAST_ABILITY_2, rate=1}
			StartAnimation(caster, animation_properties)
			Timers:CreateTimer(17 / 30, function()
				local animation_properties2 = {duration - 17 / 30, activity=ACT_DOTA_IDLE, rate=1, translate="meld"}
				StartAnimation(caster, animation_properties2)
			end)
		else
			StartAnimation(caster, {duration = duration, activity = ACT_DOTA_IDLE, rate=1, translate="meld"})
		end

		-- Animation nonsense
		-- local animation_properties = {duration = duration, activity=ACT_DOTA_IDLE, rate=1, translate="meld"}
		-- StartAnimation(caster, animation_properties)
		-- -- Timers:CreateTimer(duration, function()
		-- -- 	local animation_properties_attack = {25 / 30, activity=ACT_DOTA_ATTACK, rate=1, translate="meld"}
		-- -- 	StartAnimation(caster, animation_properties_attack)
		-- 	Timers:CreateTimer(25 / 30, function()
		-- 		EndAnimation(caster)
		-- 	end)
		-- end)
	end
end

function vajrapanis_incantation_channel:OnChannelFinish(interrupted)
	if IsServer() then
		local caster = self:GetCaster()
		local ability_level = self:GetLevel() - 1

		if not interrupted then
			caster:AddNewModifier(caster, self, "modifier_vajrapanis_charges", {duration = self:GetLevelSpecialValueFor("charges_duration", ability_level)})
			local modifier = caster:FindModifierByName("modifier_vajrapanis_charges")
			if modifier:GetStackCount() < self:GetLevelSpecialValueFor("max_charges", ability_level) then
				modifier:IncrementStackCount()
				if modifier:GetStackCount() < self:GetLevelSpecialValueFor("max_charges", ability_level) then
					if caster:GetMana() > self:GetManaCost(ability_level) then
						caster:CastAbilityNoTarget(self, caster:GetPlayerID())
					end
				end
			end
		end

		if caster:HasModifier("modifier_incantation_channeling") then
			caster:FindModifierByName("modifier_incantation_channeling"):SetDuration(0.06, true)
		end
	end
end