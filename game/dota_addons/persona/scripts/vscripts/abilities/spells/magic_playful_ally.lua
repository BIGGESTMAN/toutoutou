require "personas"

function SpellCast(keys)
	local caster = keys.caster
	local ability = CreateDummyAbility(caster, keys.ability)
	local target = keys.target

	local startParticle = ParticleManager:CreateParticle("particles/spells/magic_playful_ally_start.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(startParticle, 0, caster:GetAbsOrigin())

	local mag = caster.activePersona.attributes["mag"]
	local healing = ability:GetSpecialValueFor("heal") + mag * ability:GetSpecialValueFor("heal_magic_multiplier")
	target:Heal(healing, caster)
	FindClearSpaceForUnit(caster, target:GetAbsOrigin(), true)

	local endParticle = ParticleManager:CreateParticle("particles/spells/magic_playful_ally_end_sparkles.vpcf", PATTACH_ABSORIGIN, caster)
	ParticleManager:SetParticleControl(endParticle, 0, caster:GetAbsOrigin())

	local healParticle = ParticleManager:CreateParticle("particles/spells/magic_playful_ally_heal.vpcf", PATTACH_ABSORIGIN, target)
end