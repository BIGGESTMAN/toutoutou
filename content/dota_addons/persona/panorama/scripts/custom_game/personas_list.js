

var rootparentORG = $('#PersonaTooltipRoot')

var PersonaID = 1
function create_persona_tooltip(data){
	// find the container inside the root
	var parent = $.FindChildInContext('#PersonaAttributesContainer', rootparentORG)
	
	// create the Hero Image panel under the parent found above, assigning the panel name "hero_playerid_heroname"
	var hero = $.CreatePanel ('DOTAHeroImage', parent, PersonaID)
	// save paramaters to object
	hero.Inheroid = data.heroid
	hero.Inheroname = data.heroname
	hero.Inhero = data.hero
	hero.Inplayerid = data.playerid
	
	hero.AddClass('HeroImage')
	hero.SetPanelEvent("onactivate", heroSelect(data.hero, data.playerid, data.heroname))
	
	var HeroOverlay = $.CreatePanel ('Panel', hero, 'Hero_Overlay_'+data.playerid+'_'+data.heroname)
	HeroOverlay.AddClass('HeroImageDead')
	HeroOverlay.visible = false
	
	var ReviveButton = $.CreatePanel ('Button', parent, 'Hero_revive_'+data.playerid+'_'+data.heroname)
	ReviveButton.AddClass('HeroReviveButton')
	ReviveButton.visible = false
	ReviveButton.SetPanelEvent("onactivate", heroRevive(data.hero, data.playerid, data.heroname))
	
	var ReviveButtonLBL = $.CreatePanel ('Label', ReviveButton, 'Hero_revive_label_'+data.playerid+'_'+data.heroname)
	ReviveButtonLBL.AddClass('HeroReviveButtonText')
	ReviveButtonLBL.text = "Revive"
	ReviveButtonLBL.hittest = false
	
	var levelup = $.CreatePanel ('Panel', hero, 'Hero_levelup_'+data.playerid+'_'+data.heroname)
	levelup.AddClass('LevelUp')
	levelup.visible = false
	
	var levelupLBL = $.CreatePanel ('Label', levelup, 'Hero_levelup_label_'+data.playerid+'_'+data.heroname)
	levelupLBL.AddClass('LevelUpText')
	levelupLBL.hittest = false
	
	var selectionfocus = $.CreatePanel ('Panel', hero, 'Hero_selectionfocus_'+data.playerid+'_'+data.heroname)
	selectionfocus.AddClass('Focus')
	selectionfocus.visible = false
	
	// assign all the properties for the HeroImage panel
	hero.heroid = data.heroid
	hero.heroname = data.heroname
	hero.heroimagestyle = data.imagestyle

	var HeroStatusContainer = $.CreatePanel ('Panel', parent, 'Hero_Status_Container_'+data.playerid+'_'+data.heroname)
	HeroStatusContainer.AddClass('HeroStatusContainer')
		
	var healthbar = $.CreatePanel ('Panel', HeroStatusContainer, 'Hero_Health_'+data.playerid+'_'+data.heroname)
	healthbar.AddClass('HeroHealthBar')
	
	var manabar = $.CreatePanel ('Panel', HeroStatusContainer, 'Hero_Mana_'+data.playerid+'_'+data.heroname)
	manabar.AddClass('HeroManaBar')
	
	var abilitypoints = $.CreatePanel ('Panel', parent, 'Hero_abilitypoints_'+data.playerid+'_'+data.heroname)
	abilitypoints.AddClass('AbilityPoints')
	abilitypoints.visible = false	

	PersonaID = PersonaID + 1
}

function update_persona_tooltip(data){
	var hero = data.hero
	var selectedUnit = null
	var selectedControlledUnits = Players.GetSelectedEntities(data.playerid)
	var selectedUncontrolledUnit = Players.GetQueryUnit(data.playerid)
	// $.Msg(selectedControlledUnits, selectedUncontrolledUnit)

	if (selectedUncontrolledUnit != -1)
	{
		selectedUnit = selectedUncontrolledUnit
	}
	else
	{
		selectedUnit = selectedControlledUnits[0]
	}
	// $.Msg(selectedUnit)

	var cursorPosition = GameUI.GetCursorPosition()
	// 1920 x 1200 hardcoded hacks, fuck yeah
	var item1Location = [1400,1046]
	var itemDimensions = [82,57]
	var gapBetweenItems = [0,9]

	var mousedOverItem = null
	for (var i = 0; i < 6; i++)
	{
		var minX = item1Location[0] + (itemDimensions[0] + gapBetweenItems[0]) * (i % 3)
		var maxX = item1Location[0] + (itemDimensions[0] + gapBetweenItems[0]) * (i % 3) + itemDimensions[0]
		var minY = item1Location[1] + (itemDimensions[1] + gapBetweenItems[1]) * Math.floor(i / 3)
		var maxY = item1Location[1] + (itemDimensions[1] + gapBetweenItems[1]) * Math.floor(i / 3) + itemDimensions[1]
		// $.Msg(i + " " + minX + " " + maxX + " "  + minY + " " + maxY)
		if (cursorPosition[0] >= minX && cursorPosition[0] <= maxX
			&& cursorPosition[1] >= minY && cursorPosition[1] <= maxY)
		{
			mousedOverItem = i
			// $.Msg(mousedOverItem)
			break
		}
	}

	// $.Msg(cursorPosition)
	// $.Msg(mousedOverItem)

	var statsContainer = $('#PersonaAttributesContainer')
	var abilitiesContainer = $('#PersonaSpellsContainer')
	if (mousedOverItem != null && "attributes" in data.unitInventories[selectedUnit][mousedOverItem])
	{
		// Update stat tooltips
		var personaAttributes = data.unitInventories[selectedUnit][mousedOverItem]["attributes"]
		statsContainer.visible = true
		abilitiesContainer.visible = true

		var strengthText = $.FindChildInContext('#PersonaStrength', hero)
		strengthText.text = "Strength:" + personaAttributes["str"]

		var magicText = $.FindChildInContext('#PersonaMagic', hero)
		magicText.text = "Magic:" + personaAttributes["mag"]

		var enduranceText = $.FindChildInContext('#PersonaEndurance', hero)
		enduranceText.text = "Endurance:" + personaAttributes["endr"]

		var swiftnessText = $.FindChildInContext('#PersonaSwiftness', hero)
		swiftnessText.text = "Swiftness:" + personaAttributes["swft"]

		var agilityText = $.FindChildInContext('#PersonaAgility', hero)
		agilityText.text = "Agility:" + personaAttributes["agi"]


		// Update ability tooltips
		var personaAbilities = personaAttributes["abilities"]
		for (var i = 0;i < 6; i++)
		{
			var spellBox = abilitiesContainer.GetChild(i)
			if (i in personaAbilities)
			{
				spellBox.visible = true
				var spellText = $.FindChildInContext('#Spell' + (i + 1), hero)
				spellText.text = personaAbilities[i]
			}
			else
			{
				spellBox.visible = false
			}
		}
	}
	else
	{
		statsContainer.visible = false
		abilitiesContainer.visible = false
	}
}

(function () {
	GameEvents.Subscribe( "create_persona_tooltip", create_persona_tooltip );
	GameEvents.Subscribe( "update_persona_tooltip", update_persona_tooltip );
	
})();