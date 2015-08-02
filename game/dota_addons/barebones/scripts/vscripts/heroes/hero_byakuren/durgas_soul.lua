require "libraries/animations"
require "libraries/util"

function durgasSoulCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	-- Spend a charge
	local charge_modifier = caster:FindModifierByName("modifier_vajrapanis_charges")
	if charge_modifier:GetStackCount() > 1 then
		charge_modifier:DecrementStackCount()
	else
		charge_modifier:Destroy()
	end

	ability.target_direction = caster:GetForwardVector()
	ability.damage_absorbed = 0
	ability:ApplyDataDrivenModifier(caster, caster, keys.modifier, {})

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
	local damage = ability:GetLevelSpecialValueFor("damage", ability_level) * (1 + (ability.damage_absorbed * ability:GetLevelSpecialValueFor("damage_increase", ability_level) / 100))

	local cone_units = GetEnemiesInCone(caster, start_radius, end_radius, end_distance, caster_forward, 3)
	for _,unit in pairs(cone_units) do
		ApplyDamage({ victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
	end

	-- Create particles
	caster:SetForwardVector(ability.target_direction)

	Timers:CreateTimer(0.12, function() -- A bit of a delay to make sure the shockwave particle actually goes in the right direction
		local particle_name = "particles/byakuren/durgas_soul_a.vpcf"
		local particle = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN, caster)
		ParticleManager:SetParticleControlEnt(particle, 4, caster, PATTACH_ABSORIGIN, "attach_origin", caster:GetAbsOrigin(), true)
	end)

	local particle_name_pop = "particles/byakuren/durgas_soul_pop.vpcf"
	local particle_pop = ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControlEnt(particle_pop, 1, caster, PATTACH_ABSORIGIN, "attach_origin", caster:GetAbsOrigin(), true)
	ParticleManager:SetParticleControlEnt(particle_pop, 3, caster, PATTACH_ABSORIGIN, "attach_origin", caster:GetAbsOrigin(), true)

	-- Disable retarget ability
	local main_ability_name	= ability:GetAbilityName()
	local sub_ability_name	= "durgas_soul_retarget"
	caster:SwapAbilities(main_ability_name, sub_ability_name, true, false)
end

function updateHealth(keys)
	keys.target.old_health = keys.target:GetHealth()
end

function damageTaken(keys)
	local damage = keys.DamageTaken
	local unit = keys.unit
	local ability = keys.ability

	local newHealth = unit.old_health			
	unit:SetHealth(newHealth)
	ability.damage_absorbed = ability.damage_absorbed + damage

	print("Damage Taken pre Absorb: "..damage)
	print("Damage Absorbed: " .. ability.damage_absorbed)
end

function modifierApplied(keys)
	keys.unit:Purge(false, true, false, true, true)
end

function setTarget(keys)
	local direction = (keys.target_points[1] - keys.caster:GetAbsOrigin()):Normalized()
	local main_ability_name	= "durgas_soul"
	keys.caster:FindAbilityByName(main_ability_name).target_direction = direction
end

function updateAbilityActivated(keys)
	if keys.caster:HasModifier("modifier_vajrapanis_charges") then
		keys.ability:SetActivated(true)
	else
		keys.ability:SetActivated(false)
	end
end