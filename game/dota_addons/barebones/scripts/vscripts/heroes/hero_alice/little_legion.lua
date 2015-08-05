require "heroes/hero_alice/dolls"

function littleLegionCast(keys)
	spawnDoll(keys.ability, keys.target, keys.caster, keys.caster:GetAbsOrigin())
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

	ParticleManager:DestroyParticle(doll.tether_particle, false)
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