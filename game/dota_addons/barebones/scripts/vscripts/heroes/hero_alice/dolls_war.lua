require "libraries/animations"
require "libraries/util"

function dollsWarActivation(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	if caster.dolls then
		for doll,v in pairs(caster.dolls) do
			local doll_type = doll:GetUnitName()
			if doll_type == "shanghai_doll" then
				fireLaser(keys, doll)
			else
				spin(keys, doll)
			end
		end
	end
	
	if caster.goliath_dolls then
		for goliath_doll,v in pairs(caster.goliath_dolls) do
			caster:FindAbilityByName("goliath_doll"):ApplyDataDrivenModifier(caster, goliath_doll, keys.goliath_doll_buff, {})
		end
	end
end

function spin(keys, doll)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local team = doll:GetTeamNumber()
	local point = doll:GetAbsOrigin()
	local radius = ability:GetLevelSpecialValueFor("spin_radius", ability_level)
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	local iOrder = FIND_ANY_ORDER

	local targets = FindUnitsInRadius(team, point, nil, radius, iTeam, iType, iFlag, iOrder, false)
	local damage = ability:GetLevelSpecialValueFor("spin_damage", ability_level)

	for k,unit in pairs(targets) do
		ApplyDamage({ victim = unit, attacker = doll, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
		ability:ApplyDataDrivenModifier(doll, unit, keys.slow_modifier, {})
	end

	ParticleManager:CreateParticle(keys.spin_particle, PATTACH_ABSORIGIN, doll)
	StartAnimation(doll, {duration=23 * 0.03 / 2, activity=ACT_DOTA_RATTLETRAP_POWERCOGS, rate=2, translate = "telebolt"})
	StartSoundEvent(keys.spin_sound, doll)

end

function fireLaser(keys, doll)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local thinker_modifier = keys.thinker_modifier
	local range = ability:GetLevelSpecialValueFor("laser_range", ability_level)
	local radius = ability:GetLevelSpecialValueFor("laser_radius", ability_level)
	local direction = doll.target:GetForwardVector()

	local targets = unitsInLine(caster, ability, thinker_modifier, doll:GetAbsOrigin(), range, radius, direction, false)
	local damage = ability:GetLevelSpecialValueFor("laser_damage", ability_level)

	for k,unit in pairs(targets) do
		ApplyDamage({ victim = unit, attacker = doll, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
	end

	doll:SetForwardVector(direction) -- doesn't work?
	StartAnimation(doll, {duration=24 * 0.03, activity=ACT_DOTA_RATTLETRAP_HOOKSHOT_START, rate=1})
	StartSoundEvent(keys.laser_sound, doll)

	-- local particle = ParticleManager:CreateParticle(keys.laser_particle, PATTACH_ABSORIGIN_FOLLOW, doll)
	-- ParticleManager:SetParticleControlEnt( particle, 0, doll, PATTACH_POINT, "attach_hitloc", doll:GetAbsOrigin(), true )

	-- local particleRange = range + radius
	-- local endcapPos = doll:GetAbsOrigin() + direction * range
	-- ParticleManager:SetParticleControl( particle, 1, endcapPos )

	-- Timers:CreateTimer(0.03, function()
	-- 	ParticleManager:DestroyParticle(particle, false)
	-- end)

	local dummy_unit = CreateUnitByName("npc_dota_invisible_vision_source", doll:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, dummy_unit, thinker_modifier, {})

	local vertical_distance = 75
	dummy_unit:SetAbsOrigin(doll:GetAbsOrigin() + Vector(0,0,vertical_distance))
	local angle = VectorToAngles(doll:GetForwardVector())
	dummy_unit:SetAngles(90,angle.y,0)

	local particle = ParticleManager:CreateParticle("particles/alice/shanghai_laser.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlEnt(particle, 1, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 5, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle, 6, dummy_unit, PATTACH_POINT_FOLLOW, "attach_hitloc", dummy_unit:GetAbsOrigin(), true)
	-- time out particle dummy after a while
	Timers:CreateTimer(5, function()
		dummy_unit:RemoveSelf()
	end)
end

function updateAbilityEnabled(keys)
	local dolls_active = false

	if keys.caster.dolls then
		for k,doll in pairs(keys.caster.dolls) do
			dolls_active = true
		end
	end
	if keys.caster.goliath_dolls then
		for k,doll in pairs(keys.caster.goliath_dolls) do
			dolls_active = true
		end
	end

	if dolls_active then
		keys.ability:SetActivated(true)
	else
		keys.ability:SetActivated(false)
	end
end