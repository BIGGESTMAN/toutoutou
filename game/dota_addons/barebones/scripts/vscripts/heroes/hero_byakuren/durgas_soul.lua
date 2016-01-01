require "libraries/animations"
require "libraries/util"

function durgasSoulCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Spend a charge
	if caster.vajrapanis_charges > 1 then
		caster.vajrapanis_charges = caster.vajrapanis_charges - 1
	end

	ability.target_direction = caster:GetForwardVector()
	ability.damage_absorbed = 0
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_durgas_soul_casting", {})

	-- Animation nonsense
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local animation_properties = {duration - 17 / 30, activity=ACT_DOTA_IDLE, rate=1, translate="meld"}
	StartAnimation(caster, animation_properties)
	Timers:CreateTimer(duration, function()
		local animation_properties_attack = {25 / 30, activity=ACT_DOTA_ATTACK, rate=1, translate="meld"}
		StartAnimation(caster, animation_properties_attack)
		Timers:CreateTimer(25 / 30, function()
			EndAnimation(caster)
		end)
	end)

	local particle_name = "particles/byakuren/durgas_soul_charging.vpcf"
	local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN, caster)

	Timers:CreateTimer(duration, function()
		ParticleManager:DestroyParticle(particle, false)
	end)

	-- Enable retarget ability
	local main_ability_name	= ability:GetAbilityName()
	local sub_ability_name	= "durgas_soul_retarget"
	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
	-- caster:FindAbilityByName(sub_ability_name):SetActivated(true)

	-- Create shockwave preview particle
	caster.durgas_soul_preview_particle = ParticleManager:CreateParticleForTeam("particles/byakuren/durgas_soul/shockwave_preview.vpcf", PATTACH_ABSORIGIN, caster, caster:GetTeamNumber())
	ParticleManager:SetParticleControlForward(caster.durgas_soul_preview_particle, 0, ability.target_direction)
end

function chargeTimeFinished(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Deal damage
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local start_radius = ability:GetLevelSpecialValueFor("initial_radius", ability_level )
	local end_radius = ability:GetLevelSpecialValueFor("end_radius", ability_level )
	local end_distance = ability:GetLevelSpecialValueFor("range", ability_level )
	local caster_forward = ability.target_direction

	local damage_type = ability:GetAbilityDamageType()
	local bonus_damage_percent = ability.damage_absorbed * ability:GetLevelSpecialValueFor("damage_increase", ability_level)
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level) * (1 + bonus_damage_percent / 100)

	local cone_units = GetEnemiesInCone(caster, start_radius, end_radius, end_distance, caster_forward, 3)
	for _,unit in pairs(cone_units) do
		ApplyDamage({ victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
	end

	-- Create shockwave particle
	caster:SetForwardVector(ability.target_direction)
	local particle = ParticleManager:CreateParticle("particles/byakuren/durgas_soul_shockwave.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlForward(particle, 0, ability.target_direction)

	-- Remove preview particle
	ParticleManager:DestroyParticle(caster.durgas_soul_preview_particle, true)
	caster.durgas_soul_preview_particle = nil

	-- Disable retarget ability
	local main_ability_name	= ability:GetAbilityName()
	local sub_ability_name	= "durgas_soul_retarget"
	caster:SwapAbilities(main_ability_name, sub_ability_name, true, false)
end

function updateHealth(keys)
	keys.target.old_health = keys.target:GetHealth()
	-- print(keys.target.old_health)
end

function damageTaken(keys)
	local damage = keys.DamageTaken
	local unit = keys.unit
	local ability = keys.ability

	local newHealth = unit.old_health
	-- print(newHealth)
	unit:SetHealth(newHealth)
	ability.damage_absorbed = ability.damage_absorbed + damage
end

function modifierApplied(keys)
	keys.unit:Purge(false, true, false, true, true)
end

function setTarget(keys)
	local caster = keys.caster
	local direction = (keys.target_points[1] - caster:GetAbsOrigin()):Normalized()
	caster:FindAbilityByName("durgas_soul").target_direction = direction

	-- Update preview particle
	ParticleManager:DestroyParticle(caster.durgas_soul_preview_particle, true)
	caster.durgas_soul_preview_particle = ParticleManager:CreateParticleForTeam("particles/byakuren/durgas_soul/shockwave_preview.vpcf", PATTACH_ABSORIGIN, caster, caster:GetTeamNumber())
	ParticleManager:SetParticleControlForward(caster.durgas_soul_preview_particle, 0, direction)
end

function onUpgrade(keys)
	if keys.ability:GetLevel() == 1 then
		local sub_ability = keys.caster:FindAbilityByName("durgas_soul_retarget")
		sub_ability:SetLevel(1)
	end
end