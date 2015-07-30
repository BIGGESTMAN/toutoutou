fantasy_nature = class({})
LinkLuaModifier("modifier_fantasy_nature", "heroes/hero_reimu/modifier_fantasy_nature.lua", LUA_MODIFIER_MOTION_NONE )

function fantasy_nature:OnSpellStart()
	local caster = self:GetCaster()
	local ability = self
	local ability_level = self:GetLevel() - 1

	EmitSoundOn("Hero_Omniknight.GuardianAngel.Cast", caster)

	local duration = self:GetLevelSpecialValueFor("duration", ability_level)
	local damage_interval = self:GetLevelSpecialValueFor("damage_interval", ability_level)
	local radius = self:GetLevelSpecialValueFor("radius", ability_level)
	local damage = self:GetLevelSpecialValueFor("damage", ability_level)
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

-- function fantasyNatureExplosion( keys )
-- 	local caster = keys.caster
-- 	local ability = keys.ability
-- 	local ability_level = ability:GetLevel()
-- 	if caster:HasItemInInventory("item_ultimate_scepter") then
-- 		local targets = FindUnitsInRadius(caster:GetTeamNumber(),
-- 	                            caster:GetAbsOrigin(),
-- 	                            nil,
-- 	                            ability:GetLevelSpecialValueFor("explosion_radius", ability_level),
-- 	                            DOTA_UNIT_TARGET_TEAM_ENEMY,
-- 	                            DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
-- 	                            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
-- 	                            FIND_CLOSEST,
-- 	                            false)

-- 		local damage_table = {}
-- 		damage_table.attacker = caster
-- 		damage_table.victim = target
-- 		damage_table.damage_type = ability:GetAbilityDamageType()
-- 		damage_table.ability = ability
-- 		damage_table.damage = ability:GetLevelSpecialValueFor("explosion_damage", ability_level)

-- 		for k,target in pairs(targets) do
-- 			damage_table.victim = target
-- 			ApplyDamage(damage_table)
-- 		end

-- 		local particle = ParticleManager:CreateParticle(particle, PATTACH_POINT_FOLLOW, caster)
-- 		--ParticleManager:SetParticleControl(particle, 1, end_point_right)
-- 	end
-- end