function spawnDoll(keys)
	local movement_interval = 0.03
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target
	local caster = keys.caster

	local allied_target = target:GetTeamNumber() == caster:GetTeamNumber()
	local doll_type = nil
	if allied_target then
		doll_type = "shanghai_doll"
	else
		doll_type = "hourai_doll"
	end
	local doll = CreateUnitByName(doll_type, caster:GetAbsOrigin(), true, caster, caster, caster:GetTeamNumber())

	-- Set doll stats based on skill rank
	if ability_level > 1 then
		doll:CreatureLevelUp(ability_level - 1)
	end

	if not caster.dolls then
		caster.dolls = {}
	end
	caster.dolls[doll] = true

	ability:ApplyDataDrivenModifier(caster, doll, keys.modifier, {})
	ability:ApplyDataDrivenModifier(caster, doll, "modifier_kill", {duration = ability:GetLevelSpecialValueFor("doll_duration", ability_level)})
	local speed = ability:GetLevelSpecialValueFor("dash_speed", ability_level) * 0.03


	-- Dash towards target
	Timers:CreateTimer(0, function()
		doll.target = target
		local direction = (target:GetAbsOrigin() - doll:GetAbsOrigin()):Normalized()
		local target_distance = (target:GetAbsOrigin() - doll:GetAbsOrigin()):Length2D()

		if not allied_target then
			doll:SetForceAttackTarget(target)

			if target_distance < doll:GetAttackRange() then
				-- Check if doll is in range
				local damage = ability:GetLevelSpecialValueFor("hourai_damage", ability_level)
				ApplyDamage({ victim = target, attacker = doll, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL})
				FindClearSpaceForUnit(doll, doll:GetAbsOrigin(), false)
			else
				doll:SetAbsOrigin(doll:GetAbsOrigin() + direction * speed)
				doll:SetForwardVector(direction)
				return 0.03
			end
		else
			if target_distance < doll:GetAttackRange() then
				-- Check if doll is in range
				ability:ApplyDataDrivenModifier(doll, target, keys.shanghai_buff, {})
				FindClearSpaceForUnit(doll, doll:GetAbsOrigin(), false)
			else
				doll:SetAbsOrigin(doll:GetAbsOrigin() + direction * speed)
				doll:SetForwardVector(direction)
				return 0.03
			end
		end
	end)
end

function killDoll(keys)
	local doll = keys.target
	if not doll.target:IsNull() then doll.target:RemoveModifierByName(keys.shanghai_buff) end
	doll:ForceKill(true)
	keys.caster.dolls[doll] = nil
	local dolls_war = keys.caster:FindAbilityByName(keys.dolls_war)
	local dolls_war_level = dolls_war:GetLevel()
	if dolls_war_level > 0 then
		local team = doll:GetTeamNumber()
		local point = doll:GetAbsOrigin()
		local radius = dolls_war:GetLevelSpecialValueFor("explosion_radius", dolls_war_level)
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER

		local targets = FindUnitsInRadius(team, point, nil, radius, iTeam, iType, iFlag, iOrder, false)
		local damage = dolls_war:GetLevelSpecialValueFor("explosion_health_percent", dolls_war_level) * doll:GetMaxHealth() / 100

		for k,unit in pairs(targets) do
			ApplyDamage({ victim = unit, attacker = doll, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
		end

		ParticleManager:CreateParticle(keys.explosion_particle, PATTACH_ABSORIGIN, doll)
	end
end

function deathCheck(keys)
	local doll = keys.target
	local target = doll.target
	local doll_type = doll:GetUnitName()
	if doll_type == "shanghai_doll" then
		doll:MoveToNPC(target)
	end
	if (target:IsNull() or not target:IsAlive()) or (target:IsInvisible() and not doll:CanEntityBeSeenByMyTeam(target)) or 
		(doll_type == "hoarai_doll" and target:GetTeamNumber() == doll:GetTeamNumber()) or
		(doll_type == "shanghai_doll" and target:GetTeamNumber() ~= doll:GetTeamNumber()) then
		doll:RemoveModifierByName(keys.modifier)
	end
end