function anchor(caster, ability, target_point)
	local ability_level = ability:GetLevel() - 1

	-- Create the anchor unit
	local anchor = CreateUnitByName("anchor", caster:GetAbsOrigin(), false, caster, caster, caster:GetTeam())
	ability:ApplyDataDrivenModifier(caster, anchor, "modifier_anchor", {})
	anchor.units_hit = {}
	anchor.units_dragging = {}

	moveAnchor(caster, ability, anchor, target_point, false)

	local particle = ParticleManager:CreateParticle("particles/foundering_anchor_aura.vpcf", PATTACH_ABSORIGIN_FOLLOW, anchor)
	ParticleManager:SetParticleControl(particle, 1, Vector(ability:GetLevelSpecialValueFor("resists_reduction_radius", ability_level),0,0))
end

function pullAnchor(caster, ability, pull_destination, anchor)
	local anchor_ability = caster:FindAbilityByName("foundering_anchor")

	ability:ApplyDataDrivenModifier(caster, anchor, "modifier_pulled", {})

	-- Release dragged units
	for unit,v in pairs(anchor.units_dragging) do
		unit:RemoveModifierByName("modifier_drag")
	end
	anchor.units_hit = {}
	anchor.units_dragging = {}

	moveAnchor(caster, anchor_ability, anchor, caster:GetAbsOrigin(), true)
end

function moveAnchor(caster, ability, anchor, target_point, pulling)
	local ability_level = ability:GetLevel() - 1
	local speed = ability:GetLevelSpecialValueFor("speed", ability_level)

	local anchor_location = anchor:GetAbsOrigin()
	local direction = (target_point - anchor_location):Normalized()

	local dummy_speed = speed * 0.03
	local arrival_distance = 25
	local height_offset = Vector(0,0,75)
	local drag_distance = 50
	local drag_hitbox_offset = 200

	anchor:SetForwardVector(direction)
	if pulling then anchor:SetForwardVector(direction * -1) end -- Flipped because moving backwards
	anchor:SetAbsOrigin(anchor:GetAbsOrigin() + height_offset)

	Timers:CreateTimer(0, function()
		if not anchor:HasModifier("modifier_pulled") or pulling then
			local caster_ghosted = caster:HasModifier("modifier_ghost")
			local damage_type = DAMAGE_TYPE_PHYSICAL
			if caster_ghosted then damage_type = DAMAGE_TYPE_MAGICAL end

			anchor_location = anchor:GetAbsOrigin()
			local distance = (target_point - anchor_location):Length2D()
			local anchor_direction = anchor:GetForwardVector()
			if distance > arrival_distance then
				-- Move projectile
				anchor:SetAbsOrigin(anchor_location + direction * dummy_speed)

				-- Check for units hit
				if pulling then anchor_direction = anchor:GetForwardVector() * -1 end -- Flipped because facing backwards

				local team = caster:GetTeamNumber()
				local origin = anchor_location + anchor_direction * drag_hitbox_offset
				local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
				local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
				local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
				local iOrder = FIND_ANY_ORDER
				local radius = ability:GetLevelSpecialValueFor("drag_radius", ability_level)
				-- DebugDrawCircle(origin, Vector(180,40,40), 1, radius, true, 0.5)

				local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
				local damage = ability:GetLevelSpecialValueFor("drag_damage", ability_level)

				for k,unit in pairs(targets) do
					if not anchor.units_hit[unit] then
						ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
						anchor.units_hit[unit] = true
						if not caster_ghosted then
							ability:ApplyDataDrivenModifier(anchor, unit, "modifier_drag", {})
							anchor.units_dragging[unit] = true
						end
					end
				end

				if not caster_ghosted then
					for unit,v in pairs(anchor.units_dragging) do
						local direction_towards_anchor = (origin - unit:GetAbsOrigin()):Normalized()
						local angle = anchor_direction:Dot(direction_towards_anchor)

						local target_distance = (unit:GetAbsOrigin() - origin):Length2D()

						if target_distance > drag_distance and angle > 0 then
							local target_direction = (unit:GetAbsOrigin() - origin):Normalized()
							unit:SetAbsOrigin(origin + drag_distance * target_direction)
							unit:SetForwardVector(anchor_direction * -1) -- Force units to look backwards -- note that this doesn't actually work
						end
					end
				else
					-- Release dragged units
					for unit,v in pairs(anchor.units_dragging) do
						unit:RemoveModifierByName("modifier_drag")
						FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
						unit:SetForwardVector(anchor_direction * -1) -- Force units to look backwards -- note that this doesn't actually work
					end
					anchor.units_dragging = {}
				end

				return 0.03
			else
				anchor:SetAbsOrigin(target_point + height_offset)
				anchor:SetForwardVector((anchor:GetForwardVector() + Vector(0,0,-1)):Normalized()) -- Goofy shit to make anchor look stuck in the ground
				if pulling then anchor:SetForwardVector((anchor:GetForwardVector() + Vector(0,0,1)):Normalized()) end -- again, flipped cause backwards

				-- Release dragged units
				for unit,v in pairs(anchor.units_dragging) do
					unit:RemoveModifierByName("modifier_drag")
					FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
					unit:SetForwardVector(anchor_direction * -1) -- Force units to look backwards -- note that this doesn't actually work because of findclearspaceforunit changing their facing?
				end
				anchor.units_dragging = {}

				if not pulling then
				-- Root and damage in impact area
					local team = caster:GetTeamNumber()
					local origin = anchor_location
					local iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
					local iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
					local iFlag = DOTA_UNIT_TARGET_FLAG_NONE
					local iOrder = FIND_ANY_ORDER
					local radius = ability:GetLevelSpecialValueFor("destination_radius", ability_level)

					local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
					local damage = ability:GetLevelSpecialValueFor("destination_damage", ability_level)

					for k,unit in pairs(targets) do
						ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
						ability:ApplyDataDrivenModifier(anchor, unit, "modifier_root", {})
					end

					-- EmitSoundOn("Touhou.Anchor_Impact", anchor)

					Timers:CreateTimer(ability:GetLevelSpecialValueFor("anchor_duration", ability_level), function()
						if not anchor:IsNull() then anchor:RemoveSelf() end
					end)
				else
					anchor:RemoveSelf()
				end

				
			end
		end
	end)
end