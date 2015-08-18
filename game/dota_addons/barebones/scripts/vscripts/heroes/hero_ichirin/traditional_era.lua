function traditionalEraCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local shield_amount = ability:GetLevelSpecialValueFor("shield_amount", ability_level)

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_traditional_era", {})
	local modifier = caster:FindModifierByName("modifier_traditional_era")
	modifier.shield_amount = shield_amount
	modifier:SetStackCount(shield_amount)

	local particle = ParticleManager:CreateParticle("particles/ichirin/traditional_era_cast.vpcf", PATTACH_POINT_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(particle, 0, caster, PATTACH_POINT_FOLLOW, "attach_hitloc", caster:GetAbsOrigin(), true)
end

function updateHealth(keys)
	keys.target.old_health = keys.target:GetHealth()
end

function damageTaken(keys)
	local damage = keys.damage_taken
	local caster = keys.caster
	local ability = keys.ability

	caster:SetHealth(caster.old_health)
	local modifier = caster:FindModifierByName("modifier_traditional_era")
	modifier.shield_amount = modifier.shield_amount - damage
	if modifier.shield_amount <= 0 then
		caster:RemoveModifierByName("modifier_traditional_era")
	else
		modifier:SetStackCount(modifier.shield_amount)
	end
end