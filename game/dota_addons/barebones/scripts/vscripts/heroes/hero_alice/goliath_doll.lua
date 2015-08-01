function spawnDoll(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1

	local doll = CreateUnitByName("goliath_doll", keys.target_points[1], true, caster, caster, caster:GetTeamNumber())
	if not caster.goliath_dolls then caster.goliath_dolls = {} end
	caster.goliath_dolls[doll] = true
	doll:SetControllableByPlayer(caster:GetMainControllingPlayer(), true)
	ability:ApplyDataDrivenModifier(caster, doll, keys.modifier, {})

	if ability_level > 1 then
		doll:CreatureLevelUp(ability_level - 1)
	end

	local bash_ability = doll:FindAbilityByName(keys.bash_ability)
	bash_ability:SetLevel(ability_level)

	local cleave_ability = doll:FindAbilityByName(keys.cleave_ability)
	cleave_ability:SetLevel(1)

	ability:ApplyDataDrivenModifier(caster, doll, "modifier_kill", {duration = ability:GetLevelSpecialValueFor("duration", ability_level)})

	-- local team = caster:GetTeamNumber()
	-- local origin = keys.target_points[1]
	-- local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	-- local iType = DOTA_UNIT_TARGET_ALL
	-- local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
	-- local iOrder = FIND_ANY_ORDER
	-- local radius = 300

	-- local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	-- for k,unit in pairs(targets) do
	-- 	if unit:GetUnitName() == "npc_dota_juggernaut_healing_ward" then
	-- 		for k,v in pairs(unit) do
	-- 			print (k,v)
	-- 		end
	-- 	end
	-- end
end

function killDoll(keys)
	keys.caster.goliath_dolls[keys.target] = nil
end