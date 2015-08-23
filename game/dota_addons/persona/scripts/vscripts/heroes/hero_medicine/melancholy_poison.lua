LinkLuaModifier("modifier_melancholy_poison_damagecheck", "heroes/hero_medicine/modifier_melancholy_poison_damagecheck.lua", LUA_MODIFIER_MOTION_NONE )

function melancholyPoisonTick(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)

	-- Increment venom count
	if not caster.venom then caster.venom = 0 end

	local venom_gain_factor = 1
	if caster:HasModifier("modifier_poison_breath_hit") or caster:HasModifier("modifier_gassing_garden_hit") then
		venom_gain_factor = 2
	end
	caster.venom = caster.venom + ability:GetLevelSpecialValueFor("venom_gained_per_second", ability_level) * update_interval * venom_gain_factor

	local max_venom = ability:GetLevelSpecialValueFor("max_venom", ability_level)
	if caster.venom > max_venom then caster.venom = max_venom end

	-- If magic damage taken recently, release venom
	if caster.venom_triggered then
		caster.venom = caster.venom - ability:GetLevelSpecialValueFor("venom_released_per_second", ability_level) * update_interval

		local team = caster:GetTeamNumber()
		local point = caster:GetAbsOrigin()
		local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER

		local targets = FindUnitsInRadius(team, point, nil, radius, iTeam, iType, iFlag, iOrder, false)
		local damage = ability:GetLevelSpecialValueFor("damage_per_second", ability_level) * update_interval

		for k,unit in pairs(targets) do
			ApplyDamage({ victim = unit, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
			ability:ApplyDataDrivenModifier(caster, unit, keys.stun_modifier, {})
		end

		ParticleManager:CreateParticle(keys.particle, PATTACH_ABSORIGIN, caster)

		if caster.venom < 0 then
			caster.venom = 0
			caster.venom_triggered = false
		end
	end

	ability:ApplyDataDrivenModifier(caster, caster, keys.display_modifier, {})
	caster:FindModifierByName(keys.display_modifier):SetStackCount(caster.venom)

	-- Update particle
	if caster:IsAlive() and ability:IsCooldownReady() then
		if not caster.melancholy_poison_particle then
			caster.melancholy_poison_particle = ParticleManager:CreateParticle("particles/medicine/melancholy_poison.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			ParticleManager:SetParticleControlEnt(caster.melancholy_poison_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
		end
		local particle_radius = caster.venom / max_venom
		ParticleManager:SetParticleControl(caster.melancholy_poison_particle, 2, Vector(particle_radius,0,0))
	else
		if caster.melancholy_poison_particle then
			ParticleManager:DestroyParticle(caster.melancholy_poison_particle, false)
			caster.melancholy_poison_particle = nil
		end
	end
end

function venomRelease(keys)
	keys.caster.venom_triggered = true
end

function createDamageCheckModifier(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:AddNewModifier(caster, ability, "modifier_melancholy_poison_damagecheck", {})
end