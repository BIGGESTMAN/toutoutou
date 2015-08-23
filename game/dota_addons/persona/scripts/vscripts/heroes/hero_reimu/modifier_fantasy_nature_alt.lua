modifier_fantasy_nature_alt = class({})

function modifier_fantasy_nature_alt:OnCreated( kv )
	if IsServer() then
		local caster = self:GetCaster()

		if not caster.fantasy_nature_damage_absorbed then caster.fantasy_nature_damage_absorbed = 0 end

		local blur_particle = ParticleManager:CreateParticle("particles/reimu/fantasy_nature_blur.vpcf",
															PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(blur_particle, 0, caster:GetOrigin())
		self:AddParticle(blur_particle, false, false, -1, false, false)

		self:StartIntervalThink(0.03)
	end
end

function modifier_fantasy_nature_alt:OnIntervalThink()
	local caster = self:GetCaster()
	if IsServer() then
		caster.old_health = caster:GetHealth()
	end
end

function modifier_fantasy_nature_alt:DeclareFunctions()
	return { MODIFIER_EVENT_ON_TAKEDAMAGE }
end

function modifier_fantasy_nature_alt:OnTakeDamage(params)
	if IsServer() then
		local caster = self:GetParent()
		if params.unit == caster then
			caster.fantasy_nature_damage_absorbed = caster.fantasy_nature_damage_absorbed + params.damage

			if params.damage_type == DAMAGE_TYPE_PHYSICAL then
				local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_hit.vpcf", PATTACH_POINT_FOLLOW, caster)
				ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
				ParticleManager:SetParticleControl(particle, 1, self:GetParent():GetAbsOrigin())
				self:AddParticle(particle, false, false, -1, false, false)
				
				caster:SetHealth(caster.old_health)
			end
		elseif params.attacker == caster then
			caster.fantasy_nature_damage_absorbed = caster.fantasy_nature_damage_absorbed + params.damage
		end
	end
end

function modifier_fantasy_nature_alt:OnDestroy()
	if IsServer() then
		local caster = self:GetCaster()
		local ability = self:GetAbility()
		local ability_level = ability:GetLevel() - 1
		local radius = ability:GetLevelSpecialValueFor("radius", ability_level)
		local damage_type = ability:GetAbilityDamageType()
		local damage = ability:GetLevelSpecialValueFor("base_damage", ability_level) + ability:GetLevelSpecialValueFor("bonus_damage_percent", ability_level) * caster.fantasy_nature_damage_absorbed / 100
		caster.fantasy_nature_damage_absorbed = nil

		local particle = ParticleManager:CreateParticle("particles/reimu/fantasy_nature_explosion.vpcf",
														PATTACH_ABSORIGIN_FOLLOW, caster)

		-- EmitSoundOn("Hero_Phoenix.SuperNova.Explode", caster)

		local damage_duration = ability:GetLevelSpecialValueFor("damage_duration", ability_level)
		local damage_interval = ability:GetLevelSpecialValueFor("damage_interval", ability_level)
		local total_ticks = damage_duration / damage_interval
		local ticks = 0 
		Timers:CreateTimer(damage_interval, function()
			if ticks < total_ticks then
				local targets = FindUnitsInRadius(caster:GetTeamNumber(),
		                            caster:GetAbsOrigin(),
		                            nil,
		                        	radius,
		                            DOTA_UNIT_TARGET_TEAM_ENEMY,
		                            DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO + DOTA_UNIT_TARGET_MECHANICAL,
		                            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		                            FIND_CLOSEST,
		                            false)

				for k,target in pairs(targets) do
					ApplyDamage({victim = target, attacker = caster, damage = damage / total_ticks, damage_type = damage_type})
				end
				ticks = ticks + 1
				return damage_interval
			end
		end)
	end
end