function damageTaken(keys)
	-- print("DAMAGE TAKEN")
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.unit
	local damage = keys.damage

	local damage_percent = ability:GetSpecialValueFor("damage_taken_percent")
	local max_damage = ability:GetSpecialValueFor("max_damage")

	if caster.forbidden_games_attack_landed then
		caster.forbidden_games_attack_landed = false
		-- print("unsetting flag")
	else
		if caster:IsAlive() then
			if not ability.damage_stored then ability.damage_stored = 0 end
			ability.damage_stored = ability.damage_stored + damage_percent * damage / 100

			if ability.damage_stored >= max_damage then
				ability.damage_stored = max_damage
				ability:ApplyDataDrivenModifier(caster, caster, "modifier_forbidden_games_full", {})
				if not ability.charged_particle then
					ability.charged_particle = ParticleManager:CreateParticle("particles/aya/wind_gods_fan_charged.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
					ParticleManager:SetParticleControlEnt(ability.charged_particle, 1, caster, PATTACH_POINT_FOLLOW, "attach_origin", caster:GetAbsOrigin(), true)
				end
			end

			ability:ApplyDataDrivenModifier(caster, caster, "modifier_forbidden_games_damage_bonus", {})
			caster:FindModifierByName("modifier_forbidden_games_damage_bonus"):SetStackCount(ability.damage_stored)
		end
	end
end

function attackLanded(keys)
	-- print("ATTACK LANDED")
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	ability.damage_stored = 0
	caster:RemoveModifierByName("modifier_forbidden_games_damage_bonus")

	if caster:HasModifier("modifier_forbidden_games_full") then
		-- print("damage full: stunning target")
		caster:RemoveModifierByName("modifier_forbidden_games_full")
		if not target:IsMagicImmune() then
			ability:ApplyDataDrivenModifier(caster, target, "modifier_forbidden_games_stun", {})
		end

		ParticleManager:DestroyParticle(ability.charged_particle, false)
		ability.charged_particle = nil
	end

	caster.forbidden_games_attack_landed = true
	-- print("setting flag")
end