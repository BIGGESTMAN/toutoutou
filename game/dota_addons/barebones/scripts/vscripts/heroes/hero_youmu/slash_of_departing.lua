function auraApplied(keys)
	keys.target.slash_of_departing_damage_instances = {}
end

function allyTookDamage(keys)
	local ability = keys.ability
	if ability then -- this fucking ability.
		local ally = keys.unit
		local damage = keys.damage_taken

		for time,damage in pairs(ally.slash_of_departing_damage_instances) do -- Do some cleanup of expired damage instances - probably not strictly necessary, but w/e
			if GameRules:GetGameTime() - time > ability:GetSpecialValueFor("heal_period") then
				ally.slash_of_departing_damage_instances[time] = nil
			end
		end

		local time = GameRules:GetGameTime()
		if not ally.slash_of_departing_damage_instances[time] then ally.slash_of_departing_damage_instances[time] = 0 end
		ally.slash_of_departing_damage_instances[time] = ally.slash_of_departing_damage_instances[time] + damage
	else
		keys.unit:RemoveModifierByName("modifier_slash_of_departing_aura")
	end
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

	-- Karmic punishment charge
	-- Store healing as damage
	caster.slash_of_departing_stored_damage = healing
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_slash_of_departing_charge_stored", {})
	-- Store debuffs
	caster.slash_of_departing_stored_debuffs = {}
	local modifiers = ally:FindAllModifiers()
	for _,modifier in pairs(modifiers) do
		local modifier_caster = modifier:GetCaster()
		local modifier_duration = modifier:GetDieTime() - modifier:GetCreationTime()
		if modifier_caster:GetTeamNumber() ~= caster:GetTeamNumber() and modifier_duration > 0 then
			local modifier_ability = modifier:GetAbility()
			local modifier_name = modifier:GetName()
			table.insert(caster.slash_of_departing_stored_debuffs, {ability = modifier_ability, name = modifier_name, duration = modifier_duration})
		end
	end

	ally:Heal(healing, caster)
	ally:Purge(false, true, false, true, true)
end

function abilityLearned(keys)
	local caster = keys.caster
	if caster:HasAbility("karmic_punishing") and keys.ability:GetLevel() == 1 then -- Check for having ability in case of being an illusion
		local karmic_punishing_ability = caster:FindAbilityByName("karmic_punishing")
		karmic_punishing_ability:SetLevel(1)
	end
end