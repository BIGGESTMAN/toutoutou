if not Filters then 
	Filters = {}
	Filters.__index = Filters
end

function Filters:DamageFilter(event)
	local attacker = EntIndexToHScript(event.entindex_attacker_const)
	local target = EntIndexToHScript(event.entindex_victim_const)
	local damage_type = event.damagetype_const
	if target:HasModifier("modifier_veils_like_sky_evasion") and damage_type == DAMAGE_TYPE_PHYSICAL then
		local evasion_rate = target:FindAbilityByName("veils_like_sky"):GetSpecialValueFor("evasion")
		ParticleManager:CreateParticle("particles/general/evade_message.vpcf", PATTACH_OVERHEAD_FOLLOW, target)
		return not RollPercentage(evasion_rate)
	end
	if target:HasModifier("modifier_veils_like_sky_magic_dodge") and damage_type == DAMAGE_TYPE_MAGICAL then
		target.veils_magic_dodged = true
		target:RemoveModifierByName("modifier_veils_like_sky_magic_dodge")
		return false
	end
	return true
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