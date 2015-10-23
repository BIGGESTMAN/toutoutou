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
	if not ability.killer and health == 0 then
		caster:SetHealth(1)
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_hourai_doll_castable", {})
		caster:AddNoDraw()
		ability:SetActivated(true)
		ability.killer = keys.attacker
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
end

function revive(keys)
	local caster = keys.caster

	caster:SetHealth(caster:GetMaxHealth())
	caster:SetMana(caster:GetMaxMana())
	caster:RemoveNoDraw()
end