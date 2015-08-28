function update_persona_tooltip(data){
	var hero = data.hero
	var selectedUnit = null
	var selectedControlledUnits = Players.GetSelectedEntities(data.playerid)
	var selectedUncontrolledUnit = Players.GetQueryUnit(data.playerid)

	if (selectedUncontrolledUnit != -1)
	{
		selectedUnit = selectedUncontrolledUnit
	}
	else
	{
		selectedUnit = selectedControlledUnits[0]
	}

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
	if (mousedOverItem != null && mousedOverItem in data.unitInventories[selectedUnit] && "attributes" in data.unitInventories[selectedUnit][mousedOverItem])
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
	GameEvents.Subscribe( "update_persona_tooltip", update_persona_tooltip );
	
})();