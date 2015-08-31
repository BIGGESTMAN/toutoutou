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
	caster:PerformAttack(target, true, true, true, true)
	local bonus_damage = caster.slash_of_departing_stored_damage
	local damage_type = ability:GetAbilityDamageType()
	ApplyDamage({victim = target, attacker = caster, damage = bonus_damage, damage_type = damage_type})

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
end