function yinYangOrbsCreateDummy( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local dummy = CreateUnitByName( "npc_dummy_blank", target:GetAbsOrigin(), false, caster, caster, target:GetTeamNumber() )
	dummy:AddAbility("yin_yang_orbs_dummy")
	dummy:FindAbilityByName("yin_yang_orbs_dummy"):ApplyDataDrivenModifier( caster, dummy, "modifier_yin_yang_orbs_dummy_unit", {} )
end



function yinYangOrbsDummyCreated( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	-- if it's first bounce then we need to initialize the ability variables since we're dealing with a dummy unit
	-- else we apply damage to the target since it'll be the second bounce
	local first = false
	if caster:GetOwner():GetClassname() == "player" then
		local unit_ability = caster:FindAbilityByName("yin_yang_orbs")

		ability.bounceTable = {}
		ability.bounceCount = 1
		ability.maxBounces = unit_ability:GetLevelSpecialValueFor("bounces", unit_ability:GetLevel() - 1)
		ability.bounceRange = unit_ability:GetLevelSpecialValueFor("bounce_range", unit_ability:GetLevel() - 1)

		ability.particle_name = keys.particle
		ability.projectile_speed = 900
		first = true
	else
		--target:RemoveModifierByName(keys.modifier_slow)
		local alreadySlowed = false;
		for k,v in pairs(target:FindAllModifiers()) do
			print ("value: ", v, "; key: ", k)
			-- print (v.MODIFIER_PROPERTY_MOVESPEED_BONUS_CONSTANT)
			-- print (v.MODIFIER_PROPERTY_MOVESPEED_BASE_OVERRIDE)
			-- print (v.MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE)
			-- print (v.MODIFIER_PROPERTY_MOVESPEED_BONUS_PERCENTAGE_UNIQUE)
			-- print (v.MODIFIER_PROPERTY_MOVESPEED_BONUS_UNIQUE)
			-- print (v.MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE)
			-- print (v.MODIFIER_PROPERTY_MOVESPEED_ABSOLUTE_MIN)
			-- print (v.MODIFIER_PROPERTY_MOVESPEED_LIMIT)
			-- print (v.MODIFIER_PROPERTY_MOVESPEED_MAX)
			print ("ms thingy: ", target:GetMoveSpeedModifier(target:GetBaseMoveSpeed()))

			if target:GetMoveSpeedModifier(target:GetBaseMoveSpeed()) < target:GetBaseMoveSpeed() then
				alreadySlowed = true;
				print ("alreadyslowed")
				break;
			end
		end
		--print (target:HasModifier(keys.modifier_slow))
		ability:ApplyDataDrivenModifier(caster, target, keys.modifier_slow, {})
		--print (target:HasModifier(keys.modifier_slow))
		if alreadySlowed then
			ability:ApplyDataDrivenModifier(caster, target, keys.modifier_silence, {})
		end
	end

	if ability.bounceCount > ability.maxBounces then
		--killDummy(caster, target)
		return
	end

	local unitsNearTarget = FindUnitsInRadius(target:GetTeamNumber(),
                            target:GetAbsOrigin(),
                            nil,
                            ability.bounceRange,
                            DOTA_UNIT_TARGET_TEAM_FRIENDLY,
                            DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL,
                            DOTA_UNIT_TARGET_FLAG_NONE,
                            FIND_CLOSEST,
                            false)

	local lastTarget = ability.projectileFrom

	ability.projectileFrom = nil
	ability.projectileTo = nil

	-- find closest target, the first unit is always the projectileFrom
	-- the projectileTo will be with closest unit that wasn't the last unit (unless no others exist)
	-- this logic is a bit different from the base luna
	for k,v in pairs(unitsNearTarget) do
		if ability.projectileFrom == nil then
			ability.projectileFrom = v
		else
			ability.projectileTo = v
			if v ~= lastTarget then
				ability.projectileTo = v
				break
			end
		end
	end

	if ability.projectileTo == nil then
		killDummy(caster, target)
		return
	end

	-- increment the bounceTable which keeps track of which targets have been hit, i currently
	-- don't use it but if someone wants to go back and fix the bounce logic then it's here
	ability.bounceTable[ability.projectileTo] = ((ability.bounceTable[ability.projectileTo] or 0) + 1)
	ability.bounceCount = ability.bounceCount + 1

    local info = {
        Target = ability.projectileTo,
        Source = ability.projectileFrom,
        EffectName = ability.particle_name,
        Ability = ability,
        bDodgeable = false,
        bProvidesVision = true,
        iMoveSpeed = ability.projectile_speed,
        iVisionRadius = 0,
        iVisionTeamNumber = target:GetTeamNumber(),
        iSourceAttachment = DOTA_PROJECTILE_ATTACHMENT_ATTACK_1
    }

    ProjectileManager:CreateTrackingProjectile( info )
end

function killDummy(caster, target)
	if caster:GetClassname() == "npc_dota_base_additive" then
		caster:RemoveSelf()
	elseif target:GetClassname() == "npc_dota_base_additive" then
		target:RemoveSelf()
	end
end