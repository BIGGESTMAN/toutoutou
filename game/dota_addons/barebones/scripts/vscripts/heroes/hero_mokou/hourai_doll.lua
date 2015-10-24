require "libraries/animations"

function spellLearned(keys)
	local ability = keys.caster:FindAbilityByName("hourai_doll")
	ability:SetLevel(1)
	keys.caster:SwapAbilities("resurrection", "hourai_doll", true, true)
	ability:SetActivated(false)
end

function damageTaken(keys)
	local caster = keys.caster
	local ability = keys.ability

	local health = caster:GetHealth()
	if not ability.killer and health == 0 and caster:HasScepter() then
		caster:SetHealth(1)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_hourai_doll_castable", {})
		caster:AddNoDraw()
		ability:SetActivated(true)
		ability.killer = keys.attacker

		ability.revivable_particle = ParticleManager:CreateParticle("particles/mokou/hourai_doll/hourai_doll_revivable.vpcf", PATTACH_ABSORIGIN, caster)
	end
end

function castPeriodEnded(keys)
	local caster = keys.caster
	local ability = keys.ability

	ability:SetActivated(false)
	if not caster:HasModifier("modifier_hourai_doll_reviving") then
		caster:RemoveNoDraw()
		caster:Kill(nil, ability.killer)
		caster:SetTimeUntilRespawn(caster:GetRespawnTime() - ability:GetSpecialValueFor("castable_period"))
	end
	ability.killer = nil
end

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_hourai_doll_reviving", {})
	caster:RemoveModifierByName("modifier_hourai_doll_castable")

	ParticleManager:DestroyParticle(ability.revivable_particle, false)
	ability.revivable_particle = nil
	ParticleManager:CreateParticle("particles/mokou/hourai_doll/hourai_doll_reviving_fire_sphere.vpcf", PATTACH_ABSORIGIN, caster)
end

function revive(keys)
	local caster = keys.caster

	caster:SetHealth(caster:GetMaxHealth())
	caster:SetMana(caster:GetMaxMana())
	caster:RemoveNoDraw()

	ParticleManager:CreateParticle("particles/mokou/hourai_doll/revive_explosion.vpcf", PATTACH_ABSORIGIN, caster)
	StartAnimation(caster, {duration=37 / 30, activity=ACT_DOTA_INTRO, rate=1})
end