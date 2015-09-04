function auraApplied(keys)
	keys.target.slash_of_departing_damage_instances = {}
end

function allyTookDamage(keys)
	local ability = keys.ability
	if ability then -- this fucking ability.
		local ally = keys.unit
		local damage = keys.damage_taken

		for time,damage in pairs(ally.slash_of_departing_damage_instances) do -- Do some cleanup of expired damage instances - probably not strictly necessary, but w/e
			if GameRules:GetGameTime() - time > ability:GetSpecialValueFor("heal_period") then
				ally.slash_of_departing_damage_instances[time] = nil
			end
		end

		local time = GameRules:GetGameTime()
		if not ally.slash_of_departing_damage_instances[time] then ally.slash_of_departing_damage_instances[time] = 0 end
		ally.slash_of_departing_damage_instances[time] = ally.slash_of_departing_damage_instances[time] + damage
	else
		keys.unit:RemoveModifierByName("modifier_slash_of_departing_aura")
	end
end

function spellCast(keys)
	local caster = keys.caster
	local ability = keys.ability
	local ally = keys.target
	if not ally:HasModifier("modifier_slash_of_departing_cast_recently") then
		local healing = 0
		for time,damage in pairs(ally.slash_of_departing_damage_instances) do
			if GameRules:GetGameTime() - time <= ability:GetSpecialValueFor("heal_period") then
				healing = healing + damage
			end
		end
		local max_healing = ability:GetSpecialValueFor("max_heal")
		if healing > max_healing then healing = max_healing end

		-- Karmic punishment charge
		-- Store healing as damage
		caster.slash_of_departing_stored_damage = healing
		ability:ApplyDataDrivenModifier(caster, caster, "modifier_slash_of_departing_charge_stored", {})
		-- Store debuffs
		caster.slash_of_departing_stored_debuffs = {}
		local modifiers = ally:FindAllModifiers()
		for _,modifier in pairs(modifiers) do
			local modifier_caster = modifier:GetCaster()
			local modifier_duration = modifier:GetDieTime() - modifier:GetCreationTime()
			if modifier_caster:GetTeamNumber() ~= caster:GetTeamNumber() and modifier_duration > 0 then
				local modifier_ability = modifier:GetAbility()
				local modifier_name = modifier:GetName()
				table.insert(caster.slash_of_departing_stored_debuffs, {ability = modifier_ability, name = modifier_name, duration = modifier_duration})
			end
		end

		-- Start particle
		print("?")
		if not caster.slash_of_departing_charged_particle then
			caster.slash_of_departing_charged_particle = ParticleManager:CreateParticle("particles/youmu/slash_of_departing_charged.vpcf", PATTACH_ABSORIGIN_FOLLOW, caster)
			local min_angle = -15
			local max_angle = 15
			local angle_oscillation_time = 1
			local min_radius = 0.5
			local max_radius = 1.5
			local radius_oscillation_time = 2

			local angle_increasing = true
			local radius_increasing = true
			local particle_angle = min_angle
			local particle_radius = min_radius
			Timers:CreateTimer(0, function()
				if caster.slash_of_departing_charged_particle then
					if angle_increasing then
						particle_angle = particle_angle + ((max_angle - min_angle) / angle_oscillation_time) * 0.03
						if particle_angle > max_angle then
							particle_angle = max_angle
							angle_increasing = false
						end
					else
						particle_angle = particle_angle - ((max_angle - min_angle) / angle_oscillation_time) * 0.03
						if particle_angle < min_angle then
							particle_angle = min_angle
							angle_increasing = true
						end
					end

					if radius_increasing then
						particle_radius = particle_radius + ((max_radius - min_radius) / radius_oscillation_time) * 0.03
						if particle_radius > max_radius then
							particle_radius = max_radius
							radius_increasing = false
						end
					else
						particle_radius = particle_radius - ((max_radius - min_radius) / radius_oscillation_time) * 0.03
						if particle_radius < min_radius then
							particle_radius = min_radius
							radius_increasing = true
						end
					end

					ParticleManager:SetParticleControl(caster.slash_of_departing_charged_particle, 2, Vector(particle_angle,0,0))
					ParticleManager:SetParticleControl(caster.slash_of_departing_charged_particle, 3, Vector(particle_radius,1,1))
					print(particle_angle, particle_radius)
					return 0.03
				end
			end)
		end

		ally:Heal(healing, caster)
		ally:Purge(false, true, false, true, true)
		ability:ApplyDataDrivenModifier(caster, ally, "modifier_slash_of_departing_cast_recently", {})
	else
		ability:RefundManaCost()
		ability:EndCooldown()
	end
end

function abilityLearned(keys)
	local caster = keys.caster
	if caster:HasAbility("karmic_punishing") and keys.ability:GetLevel() == 1 then -- Check for having ability in case of being an illusion
		local karmic_punishing_ability = caster:FindAbilityByName("karmic_punishing")
		karmic_punishing_ability:SetLevel(1)
	end
end