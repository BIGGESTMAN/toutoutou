function spellLearned(keys)
	local ability = keys.ability
	ability:SetLevel(1)
	keys.caster:SwapAbilities("virudhakas_sword", "brilliance_of_mahavairocana", true, true)
end