function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local player = caster:GetPlayerID()
	local unit_name = caster:GetUnitName()
	local target_point = target:GetAbsOrigin() + (caster:GetAbsOrigin() - target:GetAbsOrigin()):Normalized() * 128 -- duels must be manly and therefore melee range
	local duration = ability:GetSpecialValueFor("duration")
	local outgoingDamage = 0
	local incomingDamage = ability:GetSpecialValueFor("damage_taken") - 100

	-- handle_UnitOwner needs to be nil, else it will crash the game.
	local illusion = CreateUnitByName(unit_name, target_point, true, caster, nil, caster:GetTeamNumber())
	illusion:SetPlayerID(caster:GetPlayerID())
	--illusion:SetControllableByPlayer(player, true)
	
	-- Level up the unit to the casters level
	local casterLevel = caster:GetLevel()
	for i=1,casterLevel-1 do
		illusion:HeroLevelUp(false)
	end

	-- Set the skill points to 0 and learn the skills of the caster
	illusion:SetAbilityPoints(0)
	for abilitySlot=0,15 do
		local ability = caster:GetAbilityByIndex(abilitySlot)
		if ability ~= nil then 
			local abilityLevel = ability:GetLevel()
			local abilityName = ability:GetAbilityName()
			local illusionAbility = illusion:FindAbilityByName(abilityName)
			illusionAbility:SetLevel(abilityLevel)
		end
	end

	-- Recreate the items of the caster
	for itemSlot=0,5 do
		local item = caster:GetItemInSlot(itemSlot)
		if item ~= nil then
			local itemName = item:GetName()
			local newItem = CreateItem(itemName, illusion, illusion)
			illusion:AddItem(newItem)
		end
	end

	-- Set the unit as an illusion
	illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
	illusion:MakeIllusion()

	-- Force duel
	local modifier_duel = "modifier_cleansed_crystal_judgment"

	local order_target = 
	{
		UnitIndex = target:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = illusion:entindex()
	}

	local order_illusion =
	{
		UnitIndex = illusion:entindex(),
		OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
		TargetIndex = target:entindex()
	}

	target:Stop()

	ExecuteOrderFromTable(order_target)
	ExecuteOrderFromTable(order_illusion)

	illusion:SetForceAttackTarget(target)
	target:SetForceAttackTarget(illusion)

	ability:ApplyDataDrivenModifier(caster, illusion, modifier_duel, {})
	illusion.cleansed_crystal_duel_target = target
	illusion.cleansed_crystal_illusion = true
	ability:ApplyDataDrivenModifier(caster, illusion, "modifier_cleansed_crystal_judgment_bonus_damage", {})

	ability:ApplyDataDrivenModifier(caster, target, modifier_duel, {})
	target.cleansed_crystal_duel_target = illusion
end

function duelEnded(keys)
	local target = keys.target

	if not target.cleansed_crystal_duel_target:IsNull() then
		target.cleansed_crystal_duel_target:SetForceAttackTarget(nil)
		target.cleansed_crystal_duel_target:RemoveModifierByName("modifier_cleansed_crystal_judgment")
	end
	target.cleansed_crystal_duel_target = nil

	target:SetForceAttackTarget(nil)
	if target.cleansed_crystal_illusion then target:Kill(keys.ability, target) end
end

function illusionAttackLanded(keys)
	local illusion = keys.attacker
	local target = keys.target
	local ability = keys.ability

	if target.guilt then
		ApplyDamage({victim = target, attacker = illusion, damage = target.guilt * ability:GetSpecialValueFor("bonus_damage"), damage_type = ability:GetAbilityDamageType()})
	end
end