busy_rod = class({})
LinkLuaModifier("modifier_busy_rod_passive", "heroes/hero_nazrin/modifier_busy_rod_passive.lua", LUA_MODIFIER_MOTION_NONE )
LinkLuaModifier("modifier_busy_rod_revealed", "heroes/hero_nazrin/modifier_busy_rod_revealed.lua", LUA_MODIFIER_MOTION_NONE )

require "libraries/util"

function busy_rod:OnSpellStart()
	if IsServer() then
		local caster = self:GetCaster()
		local target = self:GetCursorTarget()
		local ability = self

		local radius = ability:GetSpecialValueFor("laser_radius")
		local base_damage = ability:GetSpecialValueFor("damage")
		local bonus_damage = ability:GetSpecialValueFor("bonus_damage")
		local damage_type = ability:GetAbilityDamageType()

		local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
		local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
		local targets = unitsInLine(caster, caster:GetAbsOrigin(), distance, radius, direction, true, nil, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
		local total_treasures = 0
		for k,unit in pairs(targets) do
			if unit:HasModifier("modifier_busy_rod_revealed") then
				total_treasures = total_treasures + 1
			end
		end
		local damage = base_damage + bonus_damage * total_treasures
		for k,unit in pairs(targets) do
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		end

		-- Particle
		local particle_name = "particles/units/heroes/hero_tinker/tinker_laser.vpcf"
		local particle = ParticleManager:CreateParticle(particle_name, PATTACH_POINT, caster)
		ParticleManager:SetParticleControl(particle,9,caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle,1,target:GetAbsOrigin())
	end
end

function busy_rod:GetIntrinsicModifierName()
	return "modifier_busy_rod_passive"
end

function busy_rod:GetCastRange( vLocation, hTarget )
	if hTarget ~= nil then 
		if hTarget:HasModifier("modifier_busy_rod_revealed") then
			return nil
		else
			return self.BaseClass.GetCastRange(self, vLocation, hTarget)
		end
	else
		return self:GetSpecialValueFor("reveal_radius")
	end
end