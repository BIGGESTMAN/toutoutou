if not DamageFilter then 
	DamageFilter = {}
	DamageFilter.__index = DamageFilter
end

function DamageFilter:DamageFilter(event)
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