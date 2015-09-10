function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability

	local charges = ability:GetSpecialValueFor("charges")

	-- Make caster vanish
	caster:Stop()
	caster:AddNoDraw()
	ability:ApplyDataDrivenModifier(caster, caster, "modifier_super_scope", {})

	-- Enable cannon shot ability
	local main_ability_name	= ability:GetAbilityName()
	local sub_ability_name	= "fire_at_will"
	caster:SwapAbilities(main_ability_name, sub_ability_name, false, true)

	caster:SetModifierStackCount("modifier_super_scope", caster, charges)
end

function fireShot(keys)
	local caster = keys.caster
	local ability = caster:FindAbilityByName("super_scope")
	local target_point = keys.target_points[1]

	local delay = ability:GetSpecialValueFor("delay")
	local radius = ability:GetSpecialValueFor("radius")
	local damage = ability:GetSpecialValueFor("damage")
	local damage_type = ability:GetAbilityDamageType()

	Timers:CreateTimer(delay, function()
		local team = caster:GetTeamNumber()
		local origin = target_point
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER

		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		for k,unit in pairs(targets) do
			ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
		end
	end)

	local modifier = caster:FindModifierByName("modifier_super_scope")
	if modifier:GetStackCount() > 1 then
		modifier:SetStackCount(modifier:GetStackCount() - 1)
	else
		caster:RemoveModifierByName("modifier_super_scope")
	end
end

function buffExpired(keys)
	local caster = keys.caster

	caster:RemoveModifierByName("modifier_super_scope")
	caster:RemoveNoDraw()

	-- Disable cannon shot ability
	local main_ability_name	= "super_scope"
	local sub_ability_name	= "fire_at_will"
	caster:SwapAbilities(main_ability_name, sub_ability_name, true, false)
end

function onUpgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	caster:FindAbilityByName("fire_at_will"):SetLevel(ability:GetLevel())
end