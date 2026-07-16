--[[
    CS50 2D
    Pokemon

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

MenuState = Class{__includes = BaseState}

function MenuState:init(def)
    self.menu = Menu(def)
end

function MenuState:update(dt)
    self.menu:update(dt)
end

function MenuState:render()
    self.menu:render()
end