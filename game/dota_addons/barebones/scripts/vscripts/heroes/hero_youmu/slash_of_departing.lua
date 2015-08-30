function allyTookDamage(keys)
	local ability = keys.ability
	local ally = keys.unit
	local damage = keys.damage_taken

	if not ally.slash_of_departing_damage_instances then ally.slash_of_departing_damage_instances = {} end
	for time,damage in pairs(ally.slash_of_departing_damage_instances) do -- Do some cleanup of expired damage instances - probably not strictly necessary, but w/e
		if GameRules:GetGameTime() - time > ability:GetSpecialValueFor("heal_period") then
			ally.slash_of_departing_damage_instances[time] = nil
		end
	end

	local time = GameRules:GetGameTime()
	if not ally.slash_of_departing_damage_instances[time] then ally.slash_of_departing_damage_instances[time] = 0 end
	ally.slash_of_departing_damage_instances[time] = ally.slash_of_departing_damage_instances[time] + damage
end

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ally = keys.target

	local healing = 0
	for time,damage in pairs(ally.slash_of_departing_damage_instances) do
		if GameRules:GetGameTime() - time <= ability:GetSpecialValueFor("heal_period") then
			healing = healing + damage
		end
	end
	local max_healing = ability:GetSpecialValueFor("max_heal")
	if healing > max_healing then healing = max_healing end

	caster.slash_of_departing_stored_damage = healing

	ally:Heal(healing, caster)
	ally:Purge(false, true, false, true, true)
end

function abilityLearned(keys)
	local caster = keys.caster
	if keys.ability:GetLevel() == 1 then
		local karmic_punishing_ability = caster:FindAbilityByName("karmic_punishing")
		karmic_punishing_ability:SetLevel(1)
	end
end