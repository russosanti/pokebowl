--[[
    View current pokemon party and select a pokemon to swap into battle.
]]

PartyState = Class{__includes = BaseState}

function PartyState:init(party, options)
    self.party = party

    options = options or {}
    self.aliveOnly = options.aliveOnly or false
    self.mustSelect = options.mustSelect or false
    self.title = options.title or 'Creature Summary'
    self.onSelect = options.onSelect or function(x, y) end

    self.visibleIndices = self:buildVisibleIndices()
    self.currentPosition = self:findStartingPosition()

    self.panel = Panel(16, 16, VIRTUAL_WIDTH - 32, VIRTUAL_HEIGHT - 32)
end

function PartyState:buildVisibleIndices()
    if self.aliveOnly then
        return self.party:getAlivePokemonIndices()
    end

    local indices = {}
    for index = 1, #self.party.pokemon do
        table.insert(indices, index)
    end

    return indices
end

function PartyState:findStartingPosition()

    for position, partyIndex in ipairs(self.visibleIndices) do
        if partyIndex == self.party:getSelectedIndex() then
            return position
        end
    end

    -- The selected Pokemon is probably fainted and therefore
    -- absent from an alive-only list.
    return 1
end

function PartyState:getCurrentPartyIndex()
    return self.visibleIndices[self.currentPosition]
end

function PartyState:update(dt)
    if love.keyboard.wasPressed('m') then
        if not self.mustSelect then
            gSounds['blip']:stop()
            gSounds['blip']:play()
            gStateStack:pop()
        end
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
    if #self.visibleIndices <= 1 then
        return
    end

    -- Make party navigation circular
    self.currentPosition = (self.currentPosition - 1 + direction) % #self.visibleIndices + 1
    
    gSounds['blip']:stop()
    gSounds['blip']:play()
end

function PartyState:selectCurrentPokemon()
    local partyIndex = self:getCurrentPartyIndex()
    if not partyIndex then
        return
    end

    local selected, reason =
        self.party:selectPokemon(partyIndex)

    gSounds['blip']:stop()
    gSounds['blip']:play()

    if not selected then
        if reason == 'fainted' then
            gStateStack:push(DialogueState(
                'A fainted Pokemon cannot be selected!',
                function() end
            ))
        end
        return
    end

    if self.mustSelect then
        -- Remove partystate before callback
        gStateStack:pop()
    end
    self.onSelect(partyIndex, self.party.pokemon[partyIndex])
end

function PartyState:render()
    local visiblePartySize = #self.visibleIndices

    -- Dim the field behind the summary.
    love.graphics.setColor(0, 0, 0, 0.65)
    love.graphics.rectangle('fill', 0, 0, VIRTUAL_WIDTH, VIRTUAL_HEIGHT)

    self.panel:render()

    self:renderHeader(visiblePartySize)

    if visiblePartySize == 0 then
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
        local creature = self.party.pokemon[self:getCurrentPartyIndex()]

        self:renderCreature(creature, self.party:isSelected(self:getCurrentPartyIndex()))
        self:renderStats(creature)
    end

    self:renderFooter()
end

function PartyState:renderHeader(partySize)
    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.setFont(gFonts['medium'])
    love.graphics.print('Creature Summary', 28, 24)

    local displayedIndex = partySize == 0 and 0 or self.currentPosition

    local counterLabel = self.aliveOnly and 'Available' or 'Party'

    love.graphics.setFont(gFonts['small'])
    love.graphics.printf(
        string.format('%s %d / %d', counterLabel, displayedIndex, partySize),
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
    if creature.currentHP <= 0 then
        love.graphics.setColor(0.35, 0.35, 0.35, 0.65)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- All front creature textures are natively 64 by 64.
    love.graphics.draw(gTextures[creature.battleSpriteFront], 56, 72)

    -- Do not let the fainted appearance affect the remaining UI.
    love.graphics.setColor(1, 1, 1, 1)

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

    if self.mustSelect then
        love.graphics.printf(
            'Left / Right: Choose',
            24,
            178,
            VIRTUAL_WIDTH - 48,
            'center'
        )

        love.graphics.printf(
            'Enter: Send Out',
            24,
            188,
            VIRTUAL_WIDTH - 48,
            'center'
        )

        return
    end

    love.graphics.printf('Left / Right: Change Creature', 24, 178, VIRTUAL_WIDTH - 48, 'center')
    love.graphics.print('Enter: Select', 28, 188)
    love.graphics.printf('M: Close', 280, 188, 72, 'right')
end
