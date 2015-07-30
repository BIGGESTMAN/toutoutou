function movePoisonCloud(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	local speed = ability:GetLevelSpecialValueFor("travel_speed", ability_level)
	local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)

	target:SetAbsOrigin(target:GetAbsOrigin() + speed * update_interval * target:GetForwardVector())
end

function setCloudPosition(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	target:SetAbsOrigin(caster:GetAbsOrigin())
	target:SetForwardVector(caster:GetForwardVector())
end

function dealDamage(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	if caster:GetTeamNumber() ~= target:GetTeamNumber() then
		local update_interval = ability:GetLevelSpecialValueFor("update_interval", ability_level)
		local damage = ability:GetLevelSpecialValueFor("damage_per_second", ability_level) * update_interval

		ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
	end
end