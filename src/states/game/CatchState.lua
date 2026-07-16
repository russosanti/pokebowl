--[[
    Handle catching a wild pokemon attempt
]]

CatchState = Class{__includes = BaseState}

function CatchState:init(battleState)
    self.battleState = battleState
    self.party = self.battleState.player.party
    self.opponentPokemon = self.battleState.opponent.party.pokemon[1]
    self.opponentSprite = self.battleState.opponentSprite
end

function CatchState:enter()
    self:attemptCatch()
end

function CatchState:attemptCatch()
    -- 70% chance to catch
    if math.random(10) > 7 then
        self:failCatch(self.opponentPokemon.name .. 'broke free!')
        return
    end

    -- Fade opponent
    Timer.tween(0.8, {
        [self.opponentSprite] = {opacity = 0}
    }):finish(function()
        -- if the party is full, we can't catch the pokemon failsafe
        if not self.party:addPokemon(self.opponentPokemon) then
            self.opponentSprit.opacity = 1
            self:failCatch('Your party is full!')
            return
        end
        
        gStateStack:push(BattleMessageState(
            'You caught a ' .. self.opponentPokemon.name .. '!',
            function()
                gStateStack:pop()
                self:returnToField()
            end
        ))
    end)
end

function CatchState:failCatch(message)
    gStateStack:push(BattleMessageState(
        message,
        function()
            gStateStack:pop()
            gStateStack:push(BattleMenuState(BattleMenuState(self.battleState)))
        end
    ))
end

function CatchState:returnToField()
    gStateStack:push(FadeInState({r = 1, g = 1, b = 1}, 1,
        function()
            gSounds['battle-music']:stop()
            gSounds['field-music']:play()
            gStateStack:pop()
            gStateStack:push(FadeOutState({r = 1, g = 1, b = 1}, 1, function() end))
        end
    ))
end