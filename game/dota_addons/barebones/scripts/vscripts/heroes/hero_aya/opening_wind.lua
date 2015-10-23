function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target_point = keys.target_points[1]

	local update_interval = ability:GetSpecialValueFor("update_interval")
	local speed = ability:GetSpecialValueFor("speed") * update_interval
	local range = ability:GetSpecialValueFor("range")
	local radius = ability:GetSpecialValueFor("radius")
	local vision_radius = ability:GetSpecialValueFor("vision_radius")
	local vision_duration = ability:GetSpecialValueFor("vision_duration")
	local damage = ability:GetSpecialValueFor("damage")
	local damage_type = ability:GetAbilityDamageType()

	local tornado = CreateUnitByName("npc_dummy_unit", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, tornado, "modifier_opening_wind_projectile", {})
	ProjectileList:AddProjectile(tornado)

	local particle = ParticleManager:CreateParticle("particles/aya/opening_wind_tornado.vpcf", PATTACH_ABSORIGIN_FOLLOW, tornado)

	local direction = (target_point - tornado:GetAbsOrigin()):Normalized()
	direction.z = 0

	local units_hit = {}
	local distance_traveled = 0

	Timers:CreateTimer(0, function()
		if not tornado:IsNull() then
			if distance_traveled < range then
				if not tornado.frozen then
					-- Move projectile
					tornado:SetAbsOrigin(tornado:GetAbsOrigin() + direction * speed)
					distance_traveled = distance_traveled + speed

					-- Check for units hit
					local team = caster:GetTeamNumber()
					local origin = tornado:GetAbsOrigin()
					local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
					local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
					local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES
					local iOrder = FIND_ANY_ORDER
					-- DebugDrawCircle(origin, Vector(180,40,40), 0.1, radius, true, 0.2)
					local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

					for k,unit in pairs(targets) do
						if not units_hit[unit] then
							ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
							units_hit[unit] = true

							if not caster:HasModifier("modifier_opening_wind_hit") then
								caster:FindAbilityByName("illusionary_dominance"):SetActivated(true)
								ability:ApplyDataDrivenModifier(caster, caster, "modifier_opening_wind_hit", {})
							end
						end
					end
				end
				AddFOWViewer(caster:GetTeamNumber(), tornado:GetAbsOrigin(), vision_radius, vision_duration, false)
				return update_interval
			else
				tornado:RemoveSelf()
			end
		end
	end)
end

function onUpgrade(keys)
	local caster = keys.caster
	local ability = keys.ability
	local illusionary_dominance_ability = caster:FindAbilityByName(keys.sub_ability)

	illusionary_dominance_ability:SetLevel(ability:GetLevel())

	if illusionary_dominance_ability:GetLevel() == 1 then
		illusionary_dominance_ability:SetActivated( false )
	end
end

function disableIllusionaryDominance(keys)
	keys.caster:FindAbilityByName(keys.sub_ability):SetActivated(false)
end