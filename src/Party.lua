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
end

function Party:isFull()
    return #self.pokemon >= self.max
end

function Party:addPokemon(pokemon)
    if self:isFull() then
        return false
    end

    table.insert(self.pokemon, pokemon)
    return true
end

function Party:update(dt)
end

function Party:render()
end