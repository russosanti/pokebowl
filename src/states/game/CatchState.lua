--[[
    Handle catching a wild pokemon attempt
]]

CatchState = Class{__includes = BaseState}

function CatchState:init(battleState)
    self.battleState = battleState
    self.party = self.battleState.player.party
    self.opponentPokemon = self.battleState.opponent.party.pokemon[1]
    self.opponentSprite = self.battleState.opponentSprite
    self.ballTexture = gTextures['pokeball']
    self.ballVisible = false
    self.ballProgress = 0
    self.ballRotation = 0
    self.ballSize = 16
    self.throwDuration = 0.6
    self.arcHeight = 48
end

function CatchState:enter()
    -- Start near the upper-right portion of the player.
    self.ballStartX = self.battleState.playerSprite.x + 48
    self.ballStartY = self.battleState.playerSprite.y + 32
    -- Finish at the center of the opponent
    self.ballTargetX = self.opponentSprite.x + 32
    self.ballTargetY = self.opponentSprite.y + 32
    self:throwBall()
end

function CatchState:throwBall()
    self.ballVisible = true
    Timer.tween(self.throwDuration, {
        [self] = {
            ballProgress = 1,
            ballRotation = 4 * math.pi,
            ballSize = 24
        }
    }):finish(function()
        self:attemptCatch()
    end)
end

function CatchState:attemptCatch()
    -- 70% chance to catch
    if math.random(10) > 7 then
        self.ballVisible = false
        self:failCatch(self.opponentPokemon.name .. ' broke free!')
        return
    end

    -- Fade opponent
    Timer.tween(0.8, {
        [self.opponentSprite] = {opacity = 0}
    }):finish(function()
        -- if the party is full, we can't catch the pokemon failsafe
        if not self.party:addPokemon(self.opponentPokemon) then
            self.ballVisible = false
            self.opponentSprite.opacity = 1
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
            gStateStack:push(TakeTurnState(self.battleState, { opponentOnly = true }))
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

function CatchState:render()
    if not self.ballVisible then
        return
    end

    love.graphics.setColor(1, 1, 1, 1)

    love.graphics.draw(
        self.ballTexture,
        self.ballStartX + (self.ballTargetX - self.ballStartX) * self.ballProgress,
        self.ballStartY + (self.ballTargetY - self.ballStartY) * self.ballProgress -
            math.sin(self.ballProgress * math.pi) * self.arcHeight,
        self.ballRotation,
        self.ballSize / self.ballTexture:getWidth(),
        self.ballSize / self.ballTexture:getHeight(),
        self.ballTexture:getWidth() / 2,
        self.ballTexture:getHeight() / 2
    )
end