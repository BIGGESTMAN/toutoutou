fantasy_nature = class({})
LinkLuaModifier("modifier_fantasy_nature", "heroes/hero_reimu/modifier_fantasy_nature.lua", LUA_MODIFIER_MOTION_NONE )

function fantasy_nature:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local ability_level = self:GetLevel() - 1

	-- EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", caster)

	local duration = self:GetLevelSpecialValueFor("duration", ability_level)
	local damage_interval = self:GetLevelSpecialValueFor("damage_interval", ability_level)
	local radius = self:GetLevelSpecialValueFor("radius", ability_level)
	local damage = self:GetLevelSpecialValueFor("damage", ability_level) * self:GetLevelSpecialValueFor("damage_interval", ability_level)
	local explosion_radius = self:GetLevelSpecialValueFor("explosion_radius", ability_level)
	local explosion_damage = self:GetLevelSpecialValueFor("explosion_damage", ability_level)
	local damage_type = DAMAGE_TYPE_PHYSICAL
	caster:AddNewModifier(caster, self, "modifier_fantasy_nature", {duration = duration,
							damage_interval = damage_interval, radius = radius, damage = damage, explosion_radius = explosion_radius,
							explosion_damage = explosion_damage, damage_type = damage_type})
end

function fantasy_nature:GetCooldown( nLevel )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor("scepter_cooldown")
	end

	return self.BaseClass.GetCooldown( self, nLevel )
end

function fantasy_nature:GetManaCost( nLevel )
	if self:GetCaster():HasScepter() then
		return self:GetSpecialValueFor("scepter_manacost")
	end

	return self.BaseClass.GetManaCost(self, nLevel )
end