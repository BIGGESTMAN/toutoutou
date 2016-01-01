vajrapanis_incantation_channel = class({})
LinkLuaModifier("modifier_vajrapanis_charges_tracker", "heroes/hero_byakuren/modifier_vajrapanis_charges_tracker.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_vajrapanis_charges", "heroes/hero_byakuren/modifier_vajrapanis_charges.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_incantation_channeling", "heroes/hero_byakuren/modifier_incantation_channeling.lua", LUA_MODIFIER_MOTION_NONE )

if IsServer() then
	function vajrapanis_incantation_channel:OnSpellStart()
		-- if IsServer() then
			require("libraries/animations")
			local caster = self:GetCaster()

			local duration = self:GetSpecialValueFor("channel_time_per_charge")
			local modifier = caster:AddNewModifier(caster, self, "modifier_incantation_channeling", {duration = duration})

			-- Animation nonsense
			StartAnimation(caster, {duration = duration, activity=ACT_DOTA_CAST_ABILITY_2, rate=1 / duration})
		-- end
	end

	function vajrapanis_incantation_channel:OnChannelFinish(interrupted)
		-- if IsServer() then
			local caster = self:GetCaster()
			local ability = self
			local ability_level = ability:GetLevel() - 1

			local max_charges = ability:GetSpecialValueFor("max_charges")
			-- Remove charge limit if upgraded by Aghanim's
			if caster:HasScepter() then max_charges = 999 end

			if not interrupted then
				caster.vajrapanis_charges = caster.vajrapanis_charges + 1
				if caster.vajrapanis_charges > max_charges then caster.vajrapanis_charges = max_charges end
			end

			caster:RemoveModifierByName("modifier_incantation_channeling")
		-- end
	end

	function vajrapanis_incantation_channel:GetIntrinsicModifierName()
		return "modifier_vajrapanis_charges_tracker"
	end
end

function vajrapanis_incantation_channel:GetChannelTime()
	local caster = self:GetCaster()
	local ability = self

	if caster:HasScepter() then
		return ability:GetSpecialValueFor("superhuman_channel_time")
	else
		return ability.BaseClass.GetChannelTime(self)
	end
end