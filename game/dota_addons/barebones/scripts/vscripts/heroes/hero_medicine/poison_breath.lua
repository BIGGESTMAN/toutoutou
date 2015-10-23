function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local update_interval = ability:GetSpecialValueFor("update_interval")
	local speed = ability:GetSpecialValueFor("travel_speed") * update_interval
	local range = ability:GetSpecialValueFor("gas_duration") * ability:GetSpecialValueFor("travel_speed")

	local cloud = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, cloud, "modifier_poison_breath_cloud", {})
	ProjectileList:AddProjectile(cloud)

	local cloud_location = cloud:GetAbsOrigin()
	local direction = (target_point - cloud_location):Normalized()
	direction.z = 0

	local distance_traveled = 0

	Timers:CreateTimer(0, function()
		if not cloud:IsNull() then
			cloud_location = cloud:GetAbsOrigin()
			if distance_traveled < range then
				if not cloud.frozen then
					-- Move projectile
					cloud:SetAbsOrigin(cloud_location + direction * speed)
					distance_traveled = distance_traveled + speed
				end
				return update_interval
			else
				cloud:RemoveSelf()
			end
		end
	end)
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