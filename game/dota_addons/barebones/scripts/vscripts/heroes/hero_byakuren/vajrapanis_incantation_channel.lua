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
		local ability = self
		local ability_level = ability:GetLevel() - 1

		local max_charges = ability:GetSpecialValueFor("max_charges")
		-- Remove charge limit if upgraded by Aghanim's
		if caster:HasScepter() then max_charges = 999 end

		if not interrupted then
			caster:AddNewModifier(caster, ability, "modifier_vajrapanis_charges", {duration = ability:GetSpecialValueFor("charges_duration")})
			local modifier = caster:FindModifierByName("modifier_vajrapanis_charges")
			if modifier:GetStackCount() < max_charges then
				modifier:IncrementStackCount()
				if modifier:GetStackCount() < max_charges then
					if caster:GetMana() > ability:GetManaCost(ability_level) then
						caster:CastAbilityNoTarget(ability, caster:GetPlayerID())
					end
				end
			end
		end

		if caster:HasModifier("modifier_incantation_channeling") then
			caster:FindModifierByName("modifier_incantation_channeling"):SetDuration(0.06, true)
		end
	end
end

function vajrapanis_incantation_channel:GetChannelTime()
	-- if IsServer() then
		local caster = self:GetCaster()
		local ability = self

		if caster:HasScepter() then
			return ability:GetSpecialValueFor("superhuman_channel_time")
		else
			return ability.BaseClass.GetChannelTime(self)
		end
	-- end
end