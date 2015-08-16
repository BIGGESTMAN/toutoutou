function setRanged(keys)
	local caster = keys.caster
	keys.caster:SetAttackCapability(DOTA_UNIT_CAP_RANGED_ATTACK)
end

function setMelee(keys)
	local caster = keys.caster
	keys.caster:SetAttackCapability(DOTA_UNIT_CAP_MELEE_ATTACK)
end

function checkMana(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	if caster:GetMana() < ability:GetLevelSpecialValueFor("mana_cost", ability_level) then
		if ability:GetToggleState() then
			ability:ToggleAbility()
			if caster:IsAttacking() then
				caster:Interrupt()
			end
		end
		ability:SetActivated(false)
	else
		ability:SetActivated(true)
	end
end

function updateAbilityEnabled(keys)
	local dolls_active = false

	if keys.caster.dolls then
		for k,doll in pairs(keys.caster.dolls) do
			dolls_active = true
		end
	end
	if keys.caster.goliath_dolls then
		for k,doll in pairs(keys.caster.goliath_dolls) do
			dolls_active = true
		end
	end

	if dolls_active then
		keys.ability:SetActivated(true)
	else
		keys.ability:SetActivated(false)
	end
end

function yinYangOrbsCreateDummy( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	local dummy = CreateUnitByName( "npc_dummy_blank", target:GetAbsOrigin(), false, caster, caster, target:GetTeamNumber() )
	dummy:AddAbility("yin_yang_orbs_dummy")
	dummy:FindAbilityByName("yin_yang_orbs_dummy"):ApplyDataDrivenModifier( caster, dummy, "modifier_yin_yang_orbs_dummy", {} )
end

function yinYangOrbsDummyCreated( keys )
	local caster = keys.caster
	local target = keys.target
	local ability = keys.ability

	-- if it's first bounce then we need to initialize the ability variables since we're dealing with a dummy unit
	-- else we apply damage to the target since it'll be the second bounce
	if caster:GetOwner():GetClassname() == "player" then
		ability.caster = caster
		ability.unit_ability = caster:FindAbilityByName("yin_yang_orbs")
		ability.level = ability.unit_ability:GetLevel() - 1

		-- ability.bounceTable = {}
		ability.bounceCount = 1
		ability.maxBounces = ability.unit_ability:GetLevelSpecialValueFor("bounces", ability.level)
		ability.bounceRange = ability.unit_ability:GetLevelSpecialValueFor("bounce_range", ability.level)
		ability.projectile_speed = ability.unit_ability:GetLevelSpecialValueFor("projectile_speed", ability.level)
		ability.particle_name = "particles/reimu/yin_yang_scattering.vpcf"
		ability.damage = caster:GetAverageTrueAttackDamage()
	else
		-- Deal damage
		local damage_boost = 1 + ability.unit_ability:GetLevelSpecialValueFor("damage_increase", ability.level) / 100
		local damage_percent = (ability.unit_ability:GetLevelSpecialValueFor("base_damage", ability.level) / 100) * math.pow(damage_boost, ability.bounceCount - 1)
		local damage = ability.damage * damage_percent
		ApplyDamage({victim = target, attacker = ability.caster, damage = damage, damage_type = DAMAGE_TYPE_PHYSICAL})

		-- Silence target if they're slowed
		if target:IsMovementImpaired() then
			ability.unit_ability:ApplyDataDrivenModifier(caster, target, "modifier_yin_yang_orbs_silence", {})
		end
	end

	-- Play impact sound
	local volume = 0.0001 * ability.bounceCount -- this doesn't actually work
	target:EmitSoundParams("Touhou.Yin_Yang_Impact", 0, volume, 0)

	if ability.bounceCount > ability.maxBounces then
		killDummy(caster, target)
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
	else
		-- Play flight sound for new projectile
		local volume = 0.0001 * ability.bounceCount -- this doesn't actually work
		target:EmitSoundParams("Touhou.Yin_Yang_Flight", 0, volume, 0)
	end

	-- increment the bounceTable which keeps track of which targets have been hit, i currently
	-- don't use it but if someone wants to go back and fix the bounce logic then it's here
	-- ability.bounceTable[ability.projectileTo] = ((ability.bounceTable[ability.projectileTo] or 0) + 1)
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