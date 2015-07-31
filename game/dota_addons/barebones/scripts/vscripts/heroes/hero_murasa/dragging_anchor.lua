function pullAnchors(keys)
	local caster = keys.caster
	local ability = keys.ability
	local anchor_ability = keys.caster:FindAbilityByName("foundering_anchor")
	local ability_level = anchor_ability:GetLevel()

	local team = caster:GetTeamNumber()
	local origin = keys.target_points[1]
	local iTeam = DOTA_UNIT_TARGET_TEAM_FRIENDLY
	local iType = DOTA_UNIT_TARGET_BASIC
	local iFlag = DOTA_UNIT_TARGET_FLAG_INVULNERABLE
	local iOrder = FIND_ANY_ORDER
	local radius = ability:GetLevelSpecialValueFor("radius", ability_level)

	local targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)

	for k,unit in pairs(targets) do
		if unit:GetUnitName() == "anchor" and not unit:HasModifier("modifier_pulled") then
			local anchor = unit
			ability:ApplyDataDrivenModifier(caster, anchor, "modifier_pulled", {})

			local speed = anchor_ability:GetLevelSpecialValueFor("speed", ability_level)

			-- Release dragged units
			for unit,v in pairs(anchor.units_dragging) do
				unit:RemoveModifierByName(keys.drag_modifier)
			end
			anchor.units_hit = {}
			anchor.units_dragging = {}


			-- Various movement variable
			local target_point = caster:GetAbsOrigin()
			local anchor_location = anchor:GetAbsOrigin()
			local direction = (target_point - anchor_location):Normalized()

			local dummy_speed = speed * 0.03
			local arrival_distance = 25
			local height_offset = Vector(0,0,75)
			local drag_distance = 50

			anchor:SetForwardVector(direction * -1)
			anchor:SetAbsOrigin(anchor:GetAbsOrigin() + height_offset)

			Timers:CreateTimer(0, function()
				local caster_ghosted = caster:HasModifier("modifier_ghost")
				local damage_type = DAMAGE_TYPE_PHYSICAL
				if caster_ghosted then damage_type = DAMAGE_TYPE_MAGICAL end

				anchor_location = anchor:GetAbsOrigin()
				local distance = (target_point - anchor_location):Length2D()
				if distance > arrival_distance then
					-- Move projectile
					anchor:SetAbsOrigin(anchor_location + direction * dummy_speed)

					-- Check for units hit
					team = caster:GetTeamNumber()
					origin = anchor_location
					iTeam = DOTA_UNIT_TARGET_TEAM_ENEMY
					iType = DOTA_UNIT_TARGET_BASIC + DOTA_UNIT_TARGET_HERO
					iFlag = DOTA_UNIT_TARGET_FLAG_NONE
					iOrder = FIND_ANY_ORDER
					radius = anchor_ability:GetLevelSpecialValueFor("drag_radius", ability_level)

					targets = FindUnitsInRadius(team, origin, nil, radius, iTeam, iType, iFlag, iOrder, false)
					local damage = anchor_ability:GetLevelSpecialValueFor("drag_damage", ability_level)

					for k,unit in pairs(targets) do
						if not anchor.units_hit[unit] then
							ApplyDamage({victim = unit, attacker = caster, damage = damage, damage_type = damage_type})
							anchor.units_hit[unit] = true
							if not caster_ghosted then
								anchor_ability:ApplyDataDrivenModifier(anchor, unit, keys.drag_modifier, {})
								anchor.units_dragging[unit] = true
							end
						end
					end

					if not caster_ghosted then
						for unit,v in pairs(anchor.units_dragging) do
							local anchor_direction = anchor:GetForwardVector() * -1 -- Flipped because facing backwards
							local direction_towards_anchor = (anchor:GetAbsOrigin() - unit:GetAbsOrigin()):Normalized()
							local angle = anchor_direction:Dot(direction_towards_anchor)

							local target_distance = (unit:GetAbsOrigin() - anchor:GetAbsOrigin()):Length2D()

							if target_distance > drag_distance and angle > 0 then
								local target_direction = (unit:GetAbsOrigin() - anchor:GetAbsOrigin()):Normalized()
								unit:SetAbsOrigin(anchor:GetAbsOrigin() + drag_distance * target_direction)
							end
						end
					else
						-- Release dragged units
						for unit,v in pairs(anchor.units_dragging) do
							unit:RemoveModifierByName(keys.drag_modifier)
							FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
						end
						anchor.units_dragging = {}
					end

					return 0.03
				else
					anchor:SetAbsOrigin(target_point + height_offset)
					anchor:SetForwardVector((anchor:GetForwardVector() + Vector(0,0,1)):Normalized()) -- Goofy shit to make anchor look stuck in the ground; again, flipped cause backwards

					-- Release dragged units
					for unit,v in pairs(anchor.units_dragging) do
						unit:RemoveModifierByName(keys.drag_modifier)
						FindClearSpaceForUnit(unit, unit:GetAbsOrigin(), false)
					end
					anchor.units_dragging = {}

					Timers:CreateTimer(anchor_ability:GetLevelSpecialValueFor("anchor_duration", ability_level), function()
						if not anchor:IsNull() then anchor:RemoveSelf() end
					end)
				end
			end)
		end
	end
end