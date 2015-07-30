modifier_hallucination = class({})

function modifier_hallucination:OnCreated( kv )
	if IsServer() then
	end
end

function modifier_hallucination:OnIntervalThink()
	if IsServer() then
	end
end

function modifier_hallucination:IsHidden()
	return true
end

function modifier_hallucination:IsPurgable()
	return false
end

function modifier_hallucination:DeclareFunctions()
	return { MODIFIER_PROPERTY_DAMAGEOUTGOING_PERCENTAGE_ILLUSION,
			MODIFIER_PROPERTY_INCOMING_DAMAGE_PERCENTAGE }
end

function modifier_hallucination:GetModifierDamageOutgoing_Percentage_Illusion( params )
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		local illusion = self:GetParent()

		local team = caster:GetTeamNumber()
		local origin = illusion:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
		local iOrder = FIND_ANY_ORDER
		local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
		local targets_facing = 0
		for k,unit in pairs(targets) do
			local unit_facing = unit:GetForwardVector()
			local direction_towards_caster = (unit:GetAbsOrigin() - origin):Normalized()
			local angle = unit_facing:Dot(direction_towards_caster)
			if angle < 0 then
				targets_facing = targets_facing + 1
			end
		end

		return ability:GetLevelSpecialValueFor("damage_dealt_increase", ability_level) * targets_facing
	end
end

function modifier_hallucination:GetModifierIncomingDamage_Percentage(params)
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		local illusion = self:GetParent()

		local team = caster:GetTeamNumber()
		local origin = illusion:GetAbsOrigin()
		local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
		local iType = DOTA_UNIT_TARGET_HERO
		local iFlag = DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES + DOTA_UNIT_TARGET_FLAG_NOT_ILLUSIONS
		local iOrder = FIND_ANY_ORDER
		local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

		local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
		local targets_facing = 0
		for k,unit in pairs(targets) do
			local unit_facing = unit:GetForwardVector()
			local direction_towards_caster = (unit:GetAbsOrigin() - origin):Normalized()
			local angle = unit_facing:Dot(direction_towards_caster)
			if angle < 0 then
				targets_facing = targets_facing + 1
			end
		end

		return -1 * ability:GetLevelSpecialValueFor("damage_taken_reduction", ability_level) * targets_facing
	end
end