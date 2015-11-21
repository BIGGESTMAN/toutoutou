LinkLuaModifier("modifier_gold_rush_herodeath_check", "heroes/hero_nazrin/modifier_gold_rush_herodeath_check.lua", LUA_MODIFIER_MOTION_NONE )

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local mound_duration = ability:GetSpecialValueFor("duration")
	local taunt_radius = ability:GetSpecialValueFor("taunt_radius")
	local taunt_duration = ability:GetSpecialValueFor("taunt_duration")
	local base_bounty = ability:GetSpecialValueFor("base_bounty")
	local bounty_increase_damage_dealt = ability:GetSpecialValueFor("bounty_increase_damage_dealt")
	local bounty_increase_heroes_killed = ability:GetSpecialValueFor("bounty_increase_heroes_killed")
	local mound_health = ability:GetSpecialValueFor("health")

	local mound = CreateUnitByName("gold_rush_mound", target_point, true, caster, caster, caster:GetTeamNumber())
	mound:RemoveModifierByName("modifier_invulnerable")
	ability:ApplyDataDrivenModifier(caster, mound, "modifier_gold_rush_mound", {})
	mound:AddNewModifier(mound, ability, "modifier_kill", {duration = mound_duration})
	mound:AddNewModifier(mound, ability, "modifier_gold_rush_herodeath_check", {})
	mound:SetMaxHealth(mound_health)
	mound:SetHealth(mound_health)
	mound:SetAbsOrigin(target_point)

	mound.targets = {}
	mound.base_bounty = base_bounty
	mound.damage_taken = {}
	mound.damage_taken[caster:GetTeamNumber()] = 0
	mound.damage_taken[caster:GetOpposingTeamNumber()] = 0
	mound.bounty_increase_damage_dealt = bounty_increase_damage_dealt / 100
	mound.heroes_killed = 0
	mound.bounty_increase_heroes_killed = bounty_increase_heroes_killed / 100

	local team = caster:GetTeamNumber()
	local origin = target_point
	local radius = taunt_radius
	local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
	local iType = DOTA_UNIT_TARGET_HERO
	local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
	local iOrder = FIND_ANY_ORDER
	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		local attack_order = 
		{
			UnitIndex = unit:entindex(),
			OrderType = DOTA_UNIT_ORDER_ATTACK_TARGET,
			TargetIndex = mound:entindex()
		}

		unit:Stop()
		ExecuteOrderFromTable(attack_order)
		unit:SetForceAttackTarget(mound)
		ability:ApplyDataDrivenModifier(caster, unit, "modifier_gold_rush_taunt", {duration = taunt_duration})
		mound.targets[unit] = true
	end
end

function moundDestroyed(keys)
	local mound = keys.unit
	local killer = keys.attacker
	for unit,v in pairs(mound.targets) do
		if IsValidEntity(unit) then
			unit:RemoveModifierByName("modifier_gold_rush_taunt")
		end
	end

	if killer ~= mound then
		local bonus_bounty = mound.damage_taken[killer:GetOpposingTeamNumber()] * mound.bounty_increase_damage_dealt
		local total_bounty = (mound.base_bounty + bonus_bounty) * (1 + mound.heroes_killed * mound.bounty_increase_heroes_killed / 100)
		splitGoldAmongTeam(total_bounty, killer:GetTeamNumber())
	end
end

function tauntEnded(keys)
	keys.target:SetForceAttackTarget(nil)
end

function damageTaken(keys)
	local mound = keys.unit
	local attacker = keys.attacker
	mound.damage_taken[attacker:GetTeamNumber()] = mound.damage_taken[attacker:GetTeamNumber()] + keys.damage
end