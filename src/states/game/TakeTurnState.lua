--[[
    CS50 2D
    Pokemon
]]

TakeTurnState = Class{__includes = BaseState}

function TakeTurnState:init(battleState, options)
    self.battleState = battleState
    options = options or {}
    self.opponentOnly = options.opponentOnly or false
    self.playerPokemon = self.battleState.playerPokemon
    self.opponentPokemon = self.battleState.opponentPokemon

    self.playerSprite = self.battleState.playerSprite
    self.opponentSprite = self.battleState.opponentSprite

    -- figure out which pokemon is faster, as they get to attack first
    if self.playerPokemon.speed > self.opponentPokemon.speed then
        self.firstPokemon = self.playerPokemon
        self.secondPokemon = self.opponentPokemon
        self.firstSprite = self.playerSprite
        self.secondSprite = self.opponentSprite
        self.firstBar = self.battleState.playerHealthBar
        self.secondBar = self.battleState.opponentHealthBar
    else
        self.firstPokemon = self.opponentPokemon
        self.secondPokemon = self.playerPokemon
        self.firstSprite = self.opponentSprite
        self.secondSprite = self.playerSprite
        self.firstBar = self.battleState.opponentHealthBar
        self.secondBar = self.battleState.playerHealthBar
    end
end

function TakeTurnState:enter(params)
    if self.opponentOnly then
        self:takeOpponentTurn()
    else
        self:takeNormalTurn()
    end
end

function TakeTurnState:takeNormalTurn()
    self:performAttack(
        self.firstPokemon,
        self.secondPokemon,
        self.firstSprite,
        self.secondSprite,
        self.secondBar,
        function()
            self:performAttack(
                self.secondPokemon,
                self.firstPokemon,
                self.secondSprite,
                self.firstSprite,
                self.firstBar,
                function()
                    self:returnToBattleMenu()
                end
            )
        end
    )
end

function TakeTurnState:takeOpponentTurn()
    self:performAttack(
        self.opponentPokemon,
        self.playerPokemon,
        self.opponentSprite,
        self.playerSprite,
        self.battleState.playerHealthBar,
        function()
            self:returnToBattleMenu()
        end
    )
end

function TakeTurnState:performAttack(attacker, defender, attackerSprite, defenderSprite, defenderBar, onBattleContinues)
    self:attack(attacker, defender, attackerSprite, defenderSprite, defenderBar,
    function()
        -- remove the attack message
        gStateStack:pop()

        -- remove this state when the battle has ended; the victory or faint
        -- sequence continues through its retained callbacks
        if self:checkDeaths() then
            gStateStack:pop()
            return
        end

        onBattleContinues()
    end)
end

function TakeTurnState:returnToBattleMenu()
    gStateStack:pop()
    gStateStack:push(BattleMenuState(self.battleState))
end

function TakeTurnState:attack(attacker, defender, attackerSprite, defenderSprite, defenderBar, onEnd)
    
    -- first, push a message saying who's attacking, then flash the attacker
    -- this message is not allowed to take input at first, so it stays on the stack
    -- during the animation
    gStateStack:push(BattleMessageState(attacker.name .. ' attacks ' .. defender.name .. '!',
        function() end, false))

    -- pause for half a second, then play attack animation
    Timer.after(0.5, function()
        
        -- attack sound
        gSounds['powerup']:stop()
        gSounds['powerup']:play()

        -- blink the attacker sprite three times (turn on and off blinking 6 times)
        Timer.every(0.1, function()
            attackerSprite.blinking = not attackerSprite.blinking
        end)
        :limit(6)
        :finish(function()
            
            -- after finishing the blink, play a hit sound and flash the opacity of
            -- the defender a few times
            gSounds['hit']:stop()
            gSounds['hit']:play()

            Timer.every(0.1, function()
                defenderSprite.opacity = defenderSprite.opacity == 64/255 and 1 or 64/255
            end)
            :limit(6)
            :finish(function()
                
                -- shrink the defender's health bar over half a second, doing at least 1 dmg
                local dmg = math.max(1, attacker.attack - defender.defense)
                
                Timer.tween(0.5, {
                    [defenderBar] = {value = defender.currentHP - dmg}
                })
                :finish(function()
                    defender.currentHP = defender.currentHP - dmg
                    onEnd()
                end)
            end)
        end)
    end)
end

function TakeTurnState:checkDeaths()
    if self.playerPokemon.currentHP <= 0 then
        self:faint()
        return true
    elseif self.opponentPokemon.currentHP <= 0 then
        self:victory()
        return true
    end

    return false
end

function TakeTurnState:faint()

    -- drop player sprite down below the window
    Timer.tween(0.2, {
        [self.playerSprite] = {y = VIRTUAL_HEIGHT}
    })
    :finish(function()
        
        -- when finished, push a loss message
        gStateStack:push(BattleMessageState('You fainted!',
    
        function()

            -- fade in black
            gStateStack:push(FadeInState({
                r = 0, g = 0, b = 0
            }, 1,
            function()
                
                -- restore player pokemon to full health
                self.battleState.player.party:healAll()

                -- resume field music
                gSounds['battle-music']:stop()
                gSounds['field-music']:play()
                
                -- pop off the battle state and back into the field
                gStateStack:pop()
                gStateStack:push(FadeOutState({
                    r = 0, g = 0, b = 0
                }, 1, function() 
                    gStateStack:push(DialogueState('Your Pokemon has been fully restored; try again!'))
                end))
            end))
        end))
    end)
end

function TakeTurnState:victory()

    -- drop enemy sprite down below the window
    Timer.tween(0.2, {
        [self.opponentSprite] = {y = VIRTUAL_HEIGHT}
    })
    :finish(function()
        -- play victory music
        gSounds['battle-music']:stop()

        gSounds['victory-music']:setLooping(true)
        gSounds['victory-music']:play()

        -- when finished, push a victory message
        gStateStack:push(BattleMessageState('Victory!',
        
        function()

            -- sum all IVs and multiply by level to get exp amount
            local exp = (self.opponentPokemon.HPIV + self.opponentPokemon.attackIV +
                self.opponentPokemon.defenseIV + self.opponentPokemon.speedIV) * self.opponentPokemon.level

            gStateStack:push(BattleMessageState('You earned ' .. tostring(exp) .. ' experience points!',
                function() end, false))

            Timer.after(1.5, function()
                gSounds['exp']:play()

                -- animate the exp filling up
                Timer.tween(0.5, {
                    [self.battleState.playerExpBar] = {value = math.min(self.playerPokemon.currentExp + exp, self.playerPokemon.expToLevel)}
                })
                :finish(function()
                    
                    -- pop exp message off
                    gStateStack:pop()

                    self.playerPokemon.currentExp = self.playerPokemon.currentExp + exp

                    -- level up if we've gone over the needed amount
                    if self.playerPokemon.currentExp > self.playerPokemon.expToLevel then
                        
                        gSounds['levelup']:play()

                        -- set our exp to whatever the overlap is
                        self.playerPokemon.currentExp = self.playerPokemon.currentExp - self.playerPokemon.expToLevel

                        -- Level up stat increase
                        local HPIncrease, attackIncrease, defenseIncrease, speedIncrease = self.playerPokemon:levelUp()

                        gStateStack:push(BattleMessageState('Congratulations! Level Up!',
                        function()
                            self:showLevelUpMenu(HPIncrease, attackIncrease, defenseIncrease, speedIncrease)
                        end))
                    else
                        self:fadeOutWhite()
                    end
                end)
            end)
        end))
    end)
end

function TakeTurnState:fadeOutWhite()
    -- fade in
    gStateStack:push(FadeInState({
        r = 1, g = 1, b = 1
    }, 1, 
    function()

        -- resume field music
        gSounds['victory-music']:stop()
        gSounds['field-music']:play()
        
        -- pop off the battle state
        gStateStack:pop()
        gStateStack:push(FadeOutState({
            r = 1, g = 1, b = 1
        }, 1, function() end))
    end))
end

function TakeTurnState:showLevelUpMenu(HPIncrease, attackIncrease, defenseIncrease, speedIncrease)
    -- Create each stat increase menu item
    local function stat(name, finalValue, increase)
        return {
            text = string.format('%s: %d + %d --> %d', name, finalValue - increase, increase, finalValue),
            onSelect = function()
                gStateStack:pop()
                self:fadeOutWhite()
            end
        }
    end

    gStateStack:push(MenuState {
        x = 0,
        y = VIRTUAL_HEIGHT - 64,
        width = VIRTUAL_WIDTH,
        height = 64,
        font = gFonts['small'],
        showCursor = false,
        items = {
            stat('HP', self.playerPokemon.HP, HPIncrease),
            stat('Attack', self.playerPokemon.attack, attackIncrease),
            stat('Defense', self.playerPokemon.defense, defenseIncrease),
            stat('Speed', self.playerPokemon.speed, speedIncrease)
        }
    })
end
