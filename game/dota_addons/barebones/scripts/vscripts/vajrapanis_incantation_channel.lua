vajrapanis_incantation_channel = class({})
LinkLuaModifier("modifier_vajrapanis_charges", "heroes/hero_byakuren/modifier_vajrapanis_charges.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_incantation_channeling", "heroes/hero_byakuren/modifier_incantation_channeling.lua", LUA_MODIFIER_MOTION_NONE )

function vajrapanis_incantation_channel:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		if not caster:HasModifier("modifier_incantation_channeling") then
			caster:RemoveModifierByName("modifier_vajrapanis_charges")
		end

		caster:AddNewModifier(caster, self, "modifier_incantation_channeling", {duration = self:GetChannelTime() * 2})
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