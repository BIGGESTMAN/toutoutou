LinkLuaModifier("modifier_midnight_bird_ordercheck", "heroes/hero_rumia/modifier_midnight_bird_ordercheck.lua", LUA_MODIFIER_MOTION_NONE )

function midnightBirdCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	GameRules:SetCustomGameTeamMaxPlayers(6, 10)
	local playerID = caster:GetPlayerID()
	PlayerResource:SetCustomTeamAssignment(playerID, 6)

	ability:ApplyDataDrivenModifier(caster, caster, "modifier_midnight_bird", {})
	caster:AddNewModifier(caster, ability, "modifier_midnight_bird_ordercheck", {})
	caster:AddNoDraw()
	caster.midnight_units_eaten = {}

	caster.midnight_vision_dummy = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, 6)
	ability:ApplyDataDrivenModifier(caster, caster.midnight_vision_dummy, "modifier_midnight_bird_vision_dummy", {})
	-- AddFOWViewer(6, dummy_unit:GetAbsOrigin(), ability:GetLevelSpecialValueFor("radius", ability_level), ability:GetLevelSpecialValueFor("duration", ability_level), true)

	caster.midnight_particle = ParticleManager:CreateParticle("particles/rumia/midnight_bird_cloud.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControlEnt(caster.midnight_particle, 2, caster, PATTACH_ABSORIGIN, "attach_origin", caster:GetAbsOrigin(), true)

	-- Enable early cancel ability
	local main_ability_name	= ability:GetAbilityName()
	local sub_ability_name	= "midnight_bird_end"
	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)
end

function midnightBirdEnd(keys)
	local caster = keys.target

	local playerID = caster:GetPlayerID()
	PlayerResource:SetCustomTeamAssignment(playerID, caster:GetTeamNumber())

	caster:RemoveNoDraw()
	caster:RemoveModifierByName("modifier_midnight_bird_ordercheck")

	caster.midnight_vision_dummy:RemoveSelf()
	ParticleManager:DestroyParticle(caster.midnight_particle, false)

	for unit,v in pairs(caster.midnight_units_eaten) do
		unit:RemoveModifierByName("modifier_midnight_bird_eaten")
		FindClearSpaceForUnit(unit, caster:GetAbsOrigin(), false)
		if unit:GetTeamNumber() ~= caster:GetTeamNumber() then
			ApplyDamage({ victim = unit, attacker = caster, damage = 250, damage_type = DAMAGE_TYPE_MAGICAL})
		end
		unit:RemoveNoDraw()

		local unitPlayerID = unit:GetPlayerID()
		PlayerResource:SetCustomTeamAssignment(unitPlayerID, unit:GetTeamNumber())
	end

	-- Disable retarget ability
	local main_ability_name	= keys.ability:GetAbilityName()
	local sub_ability_name	= "midnight_bird_end"
	caster:SwapAbilities(main_ability_name, sub_ability_name, true, false)
end

function updateVisionAOE(keys)
	keys.target.midnight_vision_dummy:SetAbsOrigin(keys.target:GetAbsOrigin())
end

function cancel(keys)
	keys.caster:RemoveModifierByName("modifier_midnight_bird")
end

function onUpgrade(keys)
	if keys.ability:GetLevel() == 1 then
		local sub_ability = keys.caster:FindAbilityByName("midnight_bird_end")
		sub_ability:SetLevel(1)
	end
end