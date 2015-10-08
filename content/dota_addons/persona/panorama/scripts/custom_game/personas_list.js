function update_persona_tooltip(data){
	var wholeScreen = $('#PersonaAttributesContainer').GetParent()
	var screenWidth = wholeScreen.actuallayoutwidth
	var screenHeight = wholeScreen.actuallayoutheight
	// $.Msg(screenWidth)

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
	// weird resolution hackiness? hm
	var item1Location = [1400 / 1920 * screenWidth,1046 / 1200 * screenHeight]
	var itemDimensions = [82 / 1920 * screenWidth,57 / 1200 * screenHeight]
	var gapBetweenItems = [0 / 1920 * screenWidth,9 / 1200 * screenHeight]
	// $.Msg(item1Location, itemDimensions, gapBetweenItems)

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
	var resistsContainer = $('#PersonaResistsContainer')
	if (mousedOverItem != null && mousedOverItem in data.unitInventories[selectedUnit] && "attributes" in data.unitInventories[selectedUnit][mousedOverItem])
	{
		// Update stat tooltips
		var personaAttributes = data.unitInventories[selectedUnit][mousedOverItem]["attributes"]
		statsContainer.visible = true
		abilitiesContainer.visible = true
		resistsContainer.visible = true

		var strengthText = $.FindChildInContext('#PersonaStrength', hero)
		strengthText.text = "Strength:" + Math.floor(personaAttributes["str"])

		var magicText = $.FindChildInContext('#PersonaMagic', hero)
		magicText.text = "Magic:" + Math.floor(personaAttributes["mag"])

		var enduranceText = $.FindChildInContext('#PersonaEndurance', hero)
		enduranceText.text = "Endurance:" + Math.floor(personaAttributes["endr"])

		var swiftnessText = $.FindChildInContext('#PersonaSwiftness', hero)
		swiftnessText.text = "Swiftness:" + personaAttributes["swft"]

		var dexterityText = $.FindChildInContext('#PersonaDexterity', hero)
		dexterityText.text = "Dexterity:" + personaAttributes["dex"]

		var rangeText = $.FindChildInContext('#PersonaRange', hero)
		rangeText.text = "Range:" + personaAttributes["range"]


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

		// Update resist tooltips
		var resistNames = ["physical", "fire", "ice", "wind", "thunder", "light", "dark"]
		var resists = personaAttributes["resists"]
		for (var i = 0;i < 7; i++)
		{
			// var resistBox = resistsContainer.GetChild(i)
			// if (i in resists)
			// {
				// resistBox.visible = true
				// $.Msg(i + 1, " ", resistNames[i])
				var resistText = $.FindChildInContext('#Resist' + (i + 1), hero)
				resistText.text = resistNames[i] + ": " + resistStringFromType(resists[i + 1])
			// }
			// else
			// {
			// 	resistBox.visible = false
			// }
		}
	}
	else
	{
		statsContainer.visible = false
		abilitiesContainer.visible = false
		resistsContainer.visible = false
	}
}

function resistStringFromType(resistType)
{
	if (resistType == -1) {
		return "Wk"
	}
	else if (resistType == 1) {
		return "Rst"
	}
	else if (resistType == 2) {
		return "Blk"
	}
	else if (resistType == 3) {
		return "Absb"
	}
	return "--"
}

(function () {
	GameEvents.Subscribe( "update_persona_tooltip", update_persona_tooltip );
	
})();