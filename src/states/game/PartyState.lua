--[[
    View current pokemon party and select a pokemon to swap into battle.
]]

PartyState = Class{__includes = BaseState}

function PartyState:init(party)
    self.party = party
    self.currentIndex = self.party:getSelectedIndex() or 1

    self.panel = Panel(16, 16, VIRTUAL_WIDTH - 32, VIRTUAL_HEIGHT - 32)
end

function PartyState:update(dt)
    if love.keyboard.wasPressed('m') then
        gSounds['blip']:stop()
        gSounds['blip']:play()
        gStateStack:pop()
        return
    end

    if love.keyboard.wasPressed('left') then
        self:changePokemon(-1)
    elseif love.keyboard.wasPressed('right') then
        self:changePokemon(1)
    elseif love.keyboard.wasPressed('return') or love.keyboard.wasPressed('enter') then
        self:selectCurrentPokemon()
    end
end

function PartyState:changePokemon(direction)
    -- Do nothing if only one pokemon
    if #self.party.pokemon <= 1 then
        return
    end

    -- Make party navigation circular
    self.currentIndex = (self.currentIndex - 1 + direction) % #self.party.pokemon + 1
    
    gSounds['blip']:stop()
    gSounds['blip']:play()
end

function PartyState:selectCurrentPokemon()
    local selected, reason =
        self.party:selectPokemon(self.currentIndex)

    gSounds['blip']:stop()
    gSounds['blip']:play()

    if not selected and reason == 'fainted' then
        gStateStack:push(DialogueState(
            'A fainted Pokemon cannot be selected!',
            function() end
        ))
    end
end

function PartyState:render()
    local partySize = #self.party.pokemon

    -- Dim the field behind the summary.
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    self.panel:render()

    self:renderHeader(partySize)

    if partySize == 0 then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['small'])
        love.graphics.printf(
            'There are no creatures in your party.',
            24,
            100,
            VIRTUAL_WIDTH - 48,
            'center'
        )
    else
        local creature = self.party.pokemon[self.currentIndex]

        self:renderCreature(creature, self.party:isSelected(self.currentIndex))
        self:renderStats(creature)
    end

    self:renderFooter()
end

function PartyState:renderHeader(partySize)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(gFonts['medium'])
    love.graphics.print('Creature Summary', 28, 24)

    local displayedIndex = partySize == 0 and 0 or self.currentIndex

    love.graphics.setFont(gFonts['small'])
    love.graphics.printf(
        string.format('Party %d / %d', displayedIndex, partySize),
        240,
        28,
        112,
        'right'
    )

    -- Header separator.
    love.graphics.setColor(1, 1, 1, 0.35)
    love.graphics.line(24, 50, VIRTUAL_WIDTH - 24, 50)
    love.graphics.setColor(1, 1, 1, 1)
end

function PartyState:renderCreature(creature, isSelected)
    love.graphics.setColor(1, 1, 1, 1)

    -- All front creature textures are natively 64 by 64.
    love.graphics.draw(gTextures[creature.battleSpriteFront], 56, 72)

    love.graphics.setFont(gFonts['medium'])
    love.graphics.print(creature.name, 152, 58)

    if isSelected then
        love.graphics.setColor(45/255, 184/255, 45/255, 1)
        love.graphics.rectangle('fill', 272, 58, 80, 16, 3)

        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(gFonts['small'])

        love.graphics.printf('SELECTED', 272, 62, 80, 'center')
    end

    love.graphics.setFont(gFonts['small'])
    love.graphics.print('Level: ' .. tostring(creature.level), 152, 78)
end

function PartyState:renderStats(creature)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(gFonts['small'])

    love.graphics.print(
        string.format(
            'HP: %d / %d',
            creature.currentHP,
            creature.HP
        ),
        152,
        96
    )

    love.graphics.print(
        'Attack: ' .. tostring(creature.attack),
        152,
        112
    )

    love.graphics.print(
        'Defense: ' .. tostring(creature.defense),
        152,
        128
    )

    love.graphics.print(
        'Speed: ' .. tostring(creature.speed),
        152,
        144
    )

    love.graphics.print(
        'EXP: ' ..
            tostring(creature.currentExp) ..
            ' / ' ..
            tostring(creature.expToLevel),
        152,
        160
    )
end

function PartyState:renderFooter()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setFont(gFonts['small'])

    love.graphics.printf('Left / Right: Change Creature', 24, 178, VIRTUAL_WIDTH - 48, 'center')
    love.graphics.print('Enter: Select', 28, 188)
    love.graphics.printf('M: Close', 280, 188, 72, 'right')
end