LinkLuaModifier("modifier_hallucination", "heroes/hero_reisen/modifier_hallucination.lua", LUA_MODIFIER_MOTION_NONE )

function createIllusion(keys)
	local caster = keys.caster
	local player = caster:GetPlayerID()
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local unit_name = caster:GetUnitName()
	local origin = keys.target_points[1]
	local duration = ability:GetLevelSpecialValueFor("duration", ability_level)
	local outgoingDamage = ability:GetLevelSpecialValueFor("damage_dealt", ability_level) - 100
	local incomingDamage = ability:GetLevelSpecialValueFor("damage_taken", ability_level) - 100

	-- handle_UnitOwner needs to be nil, else it will crash the game.
	local illusion = CreateUnitByName(unit_name, origin, true, caster, nil, caster:GetTeamNumber())
	illusion:SetPlayerID(caster:GetPlayerID())
	illusion:SetControllableByPlayer(player, true)
	
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
	-- modifier_illusion controls many illusion properties like +Green damage not adding to the unit damage, not being able to cast spells and the team-only blue particle
	-- Without MakeIllusion the unit counts as a hero, e.g. if it dies to neutrals it says killed by neutrals, it respawns, etc.
	illusion:AddNewModifier(caster, ability, "modifier_illusion", { duration = duration, outgoing_damage = outgoingDamage, incoming_damage = incomingDamage })
	illusion:MakeIllusion()
	illusion:AddNewModifier(caster, ability, "modifier_hallucination", {})
end