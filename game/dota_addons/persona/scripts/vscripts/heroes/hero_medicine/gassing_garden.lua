function gassingGardenHit(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target

	if caster:GetTeamNumber() ~= target:GetTeamNumber() then
		local target_speed = target:GetMoveSpeedModifier(target:GetBaseMoveSpeed())
		local base_damage = ability:GetLevelSpecialValueFor("base_damage", ability_level)
		local damage = base_damage * (1 + target_speed / 100)

		ApplyDamage({ victim = target, attacker = caster, damage = damage, damage_type = DAMAGE_TYPE_MAGICAL})
	end
end

function createParticle(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ability_level = ability:GetLevel() - 1
	local target = keys.target_points[1]
	local thinker = keys.target

	local particle = ParticleManager:CreateParticle("particles/medicine/gassing_garden.vpcf", PATTACH_ABSORIGIN_FOLLOW, thinker)
	ParticleManager:SetParticleControl(particle, 1, Vector(ability:GetLevelSpecialValueFor("radius", ability_level),1,1))
	ParticleManager:SetParticleControl(particle, 2, Vector(ability:GetLevelSpecialValueFor("duration", ability_level),0,0))
end