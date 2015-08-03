modifier_fantasy_nature = class({})

function modifier_fantasy_nature:OnCreated( kv )
	if IsServer() then
		local caster = self:GetCaster()
		self.damage_interval = kv.damage_interval
		self.radius = kv.radius
		self.damage = kv.damage
		self.explosion_radius = kv.explosion_radius
		self.explosion_damage = kv.explosion_damage
		self.damage_type = kv.damage_type

		local blur_particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phantom_assassin/phantom_assassin_blur.vpcf",
															PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(blur_particle, 0, caster:GetOrigin())
		self:AddParticle(blur_particle, false, false, -1, false, false)

		self:StartIntervalThink(self.damage_interval)
	end
end

-- function modifier_fantasy_nature:GetEffectName()
-- 	return "particles/units/heroes/hero_phantom_assassin/phantom_assassin_blur.vpcf"
-- end

-- function modifier_fantasy_nature:GetEffectAttachType()
-- 	return PATTACH_POINT_FOLLOW
-- end

function modifier_fantasy_nature:IsHidden()
	return false
end

function modifier_fantasy_nature:OnIntervalThink()
	local caster = self:GetCaster()
	if IsServer() then
		local particle = ParticleManager:CreateParticle("particles/reimu/fantasy_nature_pulse_alt.vpcf",
														PATTACH_ABSORIGIN_FOLLOW, caster)
		ParticleManager:SetParticleControl(particle, 0, caster:GetOrigin())
		ParticleManager:SetParticleControl(particle, 1, caster:GetOrigin())
		ParticleManager:SetParticleControl(particle, 2, caster:GetOrigin())
		ParticleManager:SetParticleControl(particle, 3, caster:GetOrigin())
		self:AddParticle(particle, false, false, -1, false, false)

		local targets = FindUnitsInRadius(caster:GetTeamNumber(),
		                            caster:GetAbsOrigin(),
		                            nil,
		                            self.radius,
		                            DOTA_UNIT_TARGET_TEAM_ENEMY,
		                            DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
		                            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		                            FIND_CLOSEST,
		                            false)

		local damage_table = {}
		damage_table.attacker = caster
		damage_table.damage_type = self.damage_type
		damage_table.damage = self.damage
		damage_table.ability = self

		for k,unit in pairs(targets) do
			damage_table.victim = unit
			ApplyDamage(damage_table)
		end

	end
end

function modifier_fantasy_nature:DeclareFunctions()
	return { MODIFIER_EVENT_ON_ATTACKED,
			MODIFIER_PROPERTY_ABSOLUTE_NO_DAMAGE_PHYSICAL }
end

function modifier_fantasy_nature:GetAbsoluteNoDamagePhysical(params)
	return 1
end

function modifier_fantasy_nature:OnAttacked()
	local particle = ParticleManager:CreateParticle("particles/units/heroes/hero_phoenix/phoenix_supernova_hit.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
	ParticleManager:SetParticleControl(particle, 0, self:GetParent():GetAbsOrigin())
	ParticleManager:SetParticleControl(particle, 1, self:GetParent():GetAbsOrigin())
	self:AddParticle(particle, false, false, -1, false, false)
end

function modifier_fantasy_nature:OnDestroy()
	local caster = self:GetCaster()
	if IsServer() and caster:HasScepter() and caster:IsAlive() then
		local particle = ParticleManager:CreateParticle("particles/reimu/fantasy_nature_explosion.vpcf",
														PATTACH_ABSORIGIN_FOLLOW, caster)

		local targets = FindUnitsInRadius(caster:GetTeamNumber(),
		                            caster:GetAbsOrigin(),
		                            nil,
		                        	self.explosion_radius,
		                            DOTA_UNIT_TARGET_TEAM_ENEMY,
		                            DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO,
		                            DOTA_UNIT_TARGET_FLAG_MAGIC_IMMUNE_ENEMIES,
		                            FIND_CLOSEST,
		                            false)

		local damage_table = {}
		damage_table.attacker = caster
		damage_table.damage_type = self.damage_type
		damage_table.damage = self.explosion_damage

		for k,target in pairs(targets) do
			damage_table.victim = target
			ApplyDamage(damage_table)
		end

		EmitSoundOn("Hero_Phoenix.SuperNova.Explode", caster)
	end
end