function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local target = keys.target

	local particle_name = "particles/iku/swimming_thunder/sphere.vpcf"
	local sphere = CreateUnitByName("npc_dummy_unit", caster:GetOrigin(), false, caster, caster, caster:GetTeamNumber())
	ability:ApplyDataDrivenModifier(caster, sphere, "modifier_swimming_thunder_sphere", {})
	if caster:HasModifier("modifier_elekiter_dragon_palace_active") then
		sphere.elekiter = true
		caster:RemoveModifierByName("modifier_elekiter_dragon_palace_active")
		particle_name = "particles/iku/swimming_thunder/elekiter_sphere.vpcf"
	end
	ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, sphere)

	charge(sphere, caster, ability, target, true)

	if caster:HasScepter() then
		local team = caster:GetTeamNumber()
		local origin = caster:GetAbsOrigin()
		local radius = ability:GetCastRange()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		for k,unit in pairs(targets) do
			if unit ~= target and caster:CanEntityBeSeenByMyTeam(unit) then
				local scepter_sphere = CreateUnitByName("npc_dummy_unit", caster:GetOrigin(), false, caster, caster, caster:GetTeamNumber())
				ability:ApplyDataDrivenModifier(caster, scepter_sphere, "modifier_swimming_thunder_sphere", {})
				ParticleManager:CreateParticle(particle_name, PATTACH_ABSORIGIN_FOLLOW, scepter_sphere)

				charge(scepter_sphere, caster, ability, unit, true, true)
			end
		end
	end
end

function updateSphere(keys)
	local ability = keys.ability
	local sphere = keys.target

	if sphere:HasModifier("modifier_swimming_thunder_duration") then
		local team = sphere:GetTeamNumber()
		local origin = sphere:GetAbsOrigin()
		local radius = ability:GetSpecialValueFor("charge_search_radius")
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
		local iOrder = FIND_ANY_ORDER
		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

		for k,unit in pairs(targets) do
			ability:ApplyDataDrivenModifier(sphere, unit, "modifier_swimming_thunder_attack_checker", {})
			unit:FindModifierByName("modifier_swimming_thunder_attack_checker").sphere = sphere
		end
	end
end

function unitAttacked(keys)
	local caster = keys.caster
	local ability = keys.ability
	local attacker = keys.attacker
	local sphere = attacker:FindModifierByName("modifier_swimming_thunder_attack_checker").sphere
	if sphere and IsValidEntity(sphere) and not sphere.cooldown and not sphere.charging and not sphere.elekiter then
		charge(sphere, caster, ability, attacker, false)
	end
end

function unitCastAbility(keys)
	local caster = keys.caster
	local ability = keys.ability
	local unit = keys.unit
	local ability_executed = keys.event_ability
	local sphere = unit:FindModifierByName("modifier_swimming_thunder_attack_checker").sphere
	if sphere and IsValidEntity(sphere) and not sphere.cooldown and not sphere.charging and sphere.elekiter and not ability_executed:IsItem() then
		charge(sphere, caster, ability, unit, false)
	end
end

function charge(sphere, caster, ability, target, initial, scepter)
	local update_interval = ability:GetSpecialValueFor("update_interval")
	local speed = ability:GetSpecialValueFor("speed") * update_interval
	if scepter then speed = ability:GetSpecialValueFor("aghanim_scepter_speed") * update_interval end
	local damage_type = ability:GetAbilityDamageType()
	local target_damage = ability:GetSpecialValueFor("target_damage")
	local area_damage = ability:GetSpecialValueFor("area_damage")
	local passthrough_damage = ability:GetSpecialValueFor("passthrough_damage")
	local area_damage_radius = ability:GetSpecialValueFor("area_damage_radius")
	local passthrough_damage_radius = ability:GetSpecialValueFor("passthrough_damage_radius")
	local charge_cooldown = ability:GetSpecialValueFor("charge_cooldown")
	local duration = ability:GetSpecialValueFor("duration")

	local target_location = target:GetAbsOrigin()
	local sphere_location = sphere:GetAbsOrigin()
	local direction = (target_location - sphere_location):Normalized()
	local units_hit = {}
	sphere.charging = true

	local arrival_distance = speed / 2 + 5

	ProjectileList:AddProjectile(sphere)

	Timers:CreateTimer(0, function()
		if not sphere:IsNull() then
			if not target:IsNull() then target_location = target:GetAbsOrigin() end
			sphere_location = sphere:GetAbsOrigin()
			local distance = (target_location - sphere_location):Length2D()
			direction = (target_location - sphere_location):Normalized()

			if distance > arrival_distance then
				if not sphere.frozen then
					sphere:SetAbsOrigin(sphere_location + direction * speed)
					local team = caster:GetTeamNumber()
					local origin = sphere:GetAbsOrigin()
					local radius = passthrough_damage_radius
					local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
					local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
					local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
					local iOrder = FIND_ANY_ORDER
					local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

					for k,unit in pairs(targets) do
						if not units_hit[unit] then
							ApplyDamage({victim = unit, attacker = caster, damage = passthrough_damage, damage_type = damage_type})
							units_hit[unit] = true
						end
					end
				end
				return update_interval
			else
				if not target:IsNull() then
					ApplyDamage({victim = target, attacker = caster, damage = target_damage, damage_type = damage_type})
				end
				local team = caster:GetTeamNumber()
				local origin = sphere:GetAbsOrigin()
				local radius = area_damage_radius
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_ANY_ORDER
				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

				for k,unit in pairs(targets) do
					ApplyDamage({victim = unit, attacker = caster, damage = area_damage, damage_type = damage_type})
				end

				if initial then ability:ApplyDataDrivenModifier(caster, sphere, "modifier_swimming_thunder_duration", {}) end
				if not sphere:HasModifier("modifier_swimming_thunder_duration") or scepter then sphere:RemoveSelf() end
				sphere.charging = false

				ProjectileList:RemoveProjectile(sphere)
			end
		end
	end)

	sphere.cooldown = true
	Timers:CreateTimer(charge_cooldown, function()
		sphere.cooldown = false
	end)
end

function durationExpired(keys)
	local sphere = keys.target
	if not sphere.charging then
		sphere:RemoveSelf()
	end
end

function upgradeDragonPalace(keys)
	local caster = keys.caster
	local ability = keys.ability

	local dragon_palace_ability = caster:FindAbilityByName("elekiter_dragon_palace")
	dragon_palace_ability:SetLevel(ability:GetLevel())
end