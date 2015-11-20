if not Filters then 
	Filters = {}
	Filters.__index = Filters
end

function Filters:DamageFilter(event)
	local attacker = EntIndexToHScript(event.entindex_attacker_const)
	local target = EntIndexToHScript(event.entindex_victim_const)
	local damage_type = event.damagetype_const
	local damage = event.damage
	if target:HasModifier("modifier_veils_like_sky_evasion") and damage_type == DAMAGE_TYPE_PHYSICAL then
		local evasion_rate = target:FindAbilityByName("veils_like_sky"):GetSpecialValueFor("evasion")
		if RollPercentage(evasion_rate) then
			ParticleManager:CreateParticle("particles/general/evade_message.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
			return false
		end
	end
	if target:HasModifier("modifier_veils_like_sky_magic_dodge") and damage_type == DAMAGE_TYPE_MAGICAL then
		target.veils_magic_dodged = true
		target:RemoveModifierByName("modifier_veils_like_sky_magic_dodge")
		return false
	end
	if target:HasModifier("modifier_pendulum_guard") then
		local ability = target:FindModifierByName("modifier_pendulum_guard"):GetAbility()
		local caster = target:FindModifierByName("modifier_pendulum_guard"):GetCaster()
		local radius = ability:GetSpecialValueFor("radius")
		local reflect_percent = ability:GetSpecialValueFor("damage_percent")
		if attacker:GetTeamNumber() ~= caster:GetTeamNumber() and (target:GetAbsOrigin() - attacker:GetAbsOrigin()):Length2D() <= radius then
			local pre_reduction_damage = damage
			local new_post_reduction_damage = damage
			if damage_type == DAMAGE_TYPE_PHYSICAL then
				local damage_multiplier = damageMultiplierForArmor(target:GetPhysicalArmorValue())
				pre_reduction_damage = pre_reduction_damage / damage_multiplier
				new_post_reduction_damage = pre_reduction_damage * damageMultiplierForArmor(attacker:GetPhysicalArmorValue())
			elseif damage_type == DAMAGE_TYPE_MAGICAL then
				pre_reduction_damage = pre_reduction_damage / (1 - target:GetMagicalArmorValue())
				new_post_reduction_damage = pre_reduction_damage * (1 - attacker:GetMagicalArmorValue())
			end
			local damage_reflected = pre_reduction_damage * reflect_percent / 100
			target.pendulum_guard_damage_absorbed = target.pendulum_guard_damage_absorbed + damage_reflected

			attacker:ModifyHealth(attacker:GetHealth() - new_post_reduction_damage, ability, true, 0)
			-- ApplyDamage({victim = attacker, attacker = caster, damage = damage_reflected, damage_type = damage_type, damage_flags = DOTA_DAMAGE_FLAG_REFLECTION, abilityReturn = ability})
			event.damage = event.damage * (1 - reflect_percent / 100)
		end
	end
	return true
end

function damageMultiplierForArmor(armor)
	return 1 - 0.06 * armor / (1 + (0.06 * math.abs(armor)))
end

function Filters:ModifierGainedFilter(event)
	local caster = EntIndexToHScript(event.entindex_caster_const)
	local target = EntIndexToHScript(event.entindex_parent_const)
	if target:HasModifier("modifier_hells_tokamak_active") and caster:GetTeamNumber() ~= target:GetTeamNumber() then
		return false
	end
	return true
end

function Filters:ModifyGoldFilter(event)
	local hero = PlayerResource:GetPlayer(event.player_id_const):GetAssignedHero()
	if hero:HasModifier("modifier_clever_commander_debuff") and event.reliable == 0 then
		local modifier = hero:FindModifierByName("modifier_clever_commander_debuff")
		local gold_drained = event.gold * (1 - modifier.gold_drain_percent / 100)
		modifier.rat.gold_stolen = 	modifier.rat.gold_stolen + gold_drained
		event.gold = event.gold - gold_drained
	end
	return true
end