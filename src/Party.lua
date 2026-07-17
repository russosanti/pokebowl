--[[
    CS50 2D
    Pokemon

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

Party = Class{}

function Party:init(def)
    self.pokemon = def.pokemon
    self.max = def.max or 6

    -- Selected pokemon from party
    if #self.pokemon > 0 then
        self.selectedIndex = def.selectedIndex or 1
    else
        self.selectedIndex = nil
    end
end

function Party:isFull()
    return #self.pokemon >= self.max
end

function Party:addPokemon(pokemon)
    if self:isFull() then
        return false
    end

    table.insert(self.pokemon, pokemon)
    -- If party was empty somehow
    if not self.selectedIndex then
        self.selectedIndex = 1
    end

    return true
end

function Party:isValidIndex(index)
    return index ~= nil and self.pokemon[index] ~= nil
end

function Party:getSelectedIndex()
    return self.selectedIndex
end

function Party:getSelectedPokemon()
    if not self.selectedIndex then
        return nil
    end

    return self.pokemon[self.selectedIndex]
end

function Party:isSelected(index)
    return self.selectedIndex == index
end

function Party:isPokemonAlive(index)
    if not self:isValidIndex(index) then
        return false
    end

    return self.pokemon[index].currentHP > 0
end

function Party:hasAlivePokemon()
    for _, pokemon in ipairs(self.pokemon) do
        if pokemon.currentHP > 0 then
            return true
        end
    end

    return false
end

function Party:getAlivePokemonIndices()
    local indices = {}

    for index, pokemon in ipairs(self.pokemon) do
        if pokemon.currentHP > 0 then
            table.insert(indices, index)
        end
    end

    return indices
end

function Party:selectPokemon(index)
    if not self:isValidIndex(index) then
        return false, 'invalid'
    end

    if not self:isPokemonAlive(index) then
        return false, 'fainted'
    end

    self.selectedIndex = index
    return true
end

function Party:healAll()
    for _, pokemon in ipairs(self.pokemon) do
        pokemon.currentHP = pokemon.HP
    end
end

function Party:update(dt)
end

function Party:render()
end