--[[
    CS50 2D
    Pokemon

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]]

PlayState = Class{__includes = BaseState}

function PlayState:init()
    self.level = Level()

    gSounds['field-music']:setLooping(true)
    gSounds['field-music']:play()

    self.dialogueOpened = false
end

function PlayState:update(dt)

    if not self.dialogueOpened and love.keyboard.wasPressed('m') then
        gSounds['blip']:stop()
        gSounds['blip']:play()
        gStateStack:push(PartyState(self.level.player.party))

        return
    end

    if not self.dialogueOpened and love.keyboard.wasPressed('p') then
        
        -- heal player pokemon
        gSounds['heal']:play()
        self.level.player.party:healAll()
        
        -- show a dialogue for it, allowing us to do so again when closed
        gStateStack:push(DialogueState('Your Pokemon have been healed!',
            function()
                self.dialogueOpened = false
            end))
    end

    self.level:update(dt)
end

function PlayState:render()
    self.level:render()
end