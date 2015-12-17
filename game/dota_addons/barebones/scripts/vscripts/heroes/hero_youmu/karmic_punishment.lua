require "heroes/hero_youmu/eternal_truth"

function updateEnabled(keys)
	local caster = keys.caster
	local ability = keys.ability
	ability:SetActivated(caster:HasModifier("modifier_slash_of_departing_charge_stored"))
end

function spellCast(keys)
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	-- Deal damage
	caster:PerformAttack(target, true, true, true, true, false)
	local bonus_damage = caster.slash_of_departing_stored_damage
	local damage_type = ability:GetAbilityDamageType()
	ApplyDamage({victim = target, attacker = caster, damage = bonus_damage, damage_type = damage_type})
	echoDamage(caster, bonus_damage, damage_type)
	echoDamage(caster, caster:GetAverageTrueAttackDamage(), DAMAGE_TYPE_PHYSICAL)

	-- Apply debuffs
	for k,modifier in pairs(caster.slash_of_departing_stored_debuffs) do
		-- Try both ways cause idk how this works
		local modifier_ability = modifier["ability"]
		if modifier_ability.ApplyDataDrivenModifier then
			modifier["ability"]:ApplyDataDrivenModifier(caster, target, modifier["name"], {duration = modifier["duration"]})
		else
			target:AddNewModifier(caster, modifier["ability"], modifier["name"], {duration = modifier["duration"]})
		end
	end

	caster.slash_of_departing_stored_damage = nil
	caster.slash_of_departing_stored_debuffs = nil
	caster:RemoveModifierByName("modifier_slash_of_departing_charge_stored")

	ParticleManager:DestroyParticle(caster.slash_of_departing_charged_particle, false)
	caster.slash_of_departing_charged_particle = nil

	-- Create cast particles
	local slash_dummy = CreateUnitByName("npc_dummy_unit", target:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	Timers:CreateTimer(2,function()
		slash_dummy:RemoveSelf()
	end)
	ParticleManager:CreateParticle("particles/youmu/karmic_punishment_slash.vpcf", PATTACH_ABSORIGIN, slash_dummy)

	local swirl_dummy = CreateUnitByName("npc_dummy_unit", target:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	local vertical_offset = 700
	local start_radius = 100
	local end_radius = 25
	local particle_duration = 0.5
	local target_point = target:GetAbsOrigin()

	local radius = start_radius
	local vertical_position = vertical_offset
	local particle = ParticleManager:CreateParticle("particles/youmu/karmic_punishment_swirl.vpcf", PATTACH_ABSORIGIN_FOLLOW, swirl_dummy)
	ParticleManager:CreateParticle("particles/youmu/karmic_punishment_light.vpcf", PATTACH_ABSORIGIN, target)

	ParticleManager:SetParticleControl(particle, 4, target_point + Vector(0,0,vertical_offset))  -- Set beam endpoints
	ParticleManager:SetParticleControl(particle, 5, target_point)

	Timers:CreateTimer(0, function()
		if vertical_position > 0 then
			radius = radius - ((start_radius - end_radius) / particle_duration) * 0.03
			vertical_position = vertical_position - (vertical_offset / particle_duration) * 0.03

			swirl_dummy:SetAbsOrigin(target_point + Vector(0,0,vertical_position))
			ParticleManager:SetParticleControl(particle, 2, Vector(radius,0,0))
			return 0.03
		else
			ParticleManager:DestroyParticle(particle, false)
			swirl_dummy:RemoveSelf()
		end
	end)
end