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
		print("br1")
		local direction = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Normalized()
		local distance = (target:GetAbsOrigin() - caster:GetAbsOrigin()):Length2D()
		local targets = unitsInLine(caster, caster:GetAbsOrigin(), distance, radius, direction, true, nil, DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES)
		local total_treasures = 0
		print("br2")
		for k,unit in pairs(targets) do
			if unit:HasModifier("modifier_busy_rod_revealed") then
				total_treasures = total_treasures + 1
			end
		end
		print("br3")
		total_treasures = total_treasures + runesInLine(caster:GetAbsOrigin(), direction, distance, radius)

		print("br4")
		local damage = base_damage + bonus_damage * total_treasures
		for k,unit in pairs(targets) do
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		end
		print("br5")

		-- Particle
		local particle_name = "particles/units/heroes/hero_tinker/tinker_laser.vpcf"
		local particle = ParticleManager:CreateParticle(particle_name, PATTACH_POINT, caster)
		ParticleManager:SetParticleControl(particle,9,caster:GetAbsOrigin())
		ParticleManager:SetParticleControl(particle,1,target:GetAbsOrigin())
		print("br6")
	end
end

function busy_rod:GetIntrinsicModifierName()
	return "modifier_busy_rod_passive"
end

function busy_rod:GetCastRange( vLocation, hTarget )
	print("brCR1")
	if hTarget ~= nil then
		print("brCR2")
		if hTarget:HasModifier("modifier_busy_rod_revealed") then
			print("brCR3")
			return nil
		else
			print("brCR4")
			return self:GetSpecialValueFor("normal_cast_range")
		end
	else
		print("brCR5")
		return self:GetSpecialValueFor("reveal_radius")
	end
end

function runesInLine(origin, direction, distance, width)
	print("runesInLine()")
	local pathStartPos	= origin * Vector(1,1,0)
	local line_midpoint = pathStartPos + direction * distance / 2
	local pathEndPos	= pathStartPos + direction * distance
	local radius 		= distance / 2 + width
	local allEntities = Entities:FindAllInSphere(line_midpoint, radius)
	local runes = 0
	for k,v in pairs(allEntities) do
		if v:GetDebugName() == "dota_item_rune" then
			local distance = DistancePointSegment(v:GetAbsOrigin() * Vector(1,1,0), pathStartPos, pathEndPos)
			if distance <= width then runes = runes + 1 end
		end
	end
	print("runes: ", runes)
	return runes
end