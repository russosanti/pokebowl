Pokebowl

A Pokémon-inspired role-playing game developed in Lua using LÖVE2D.

Overview

This project extends the turn-based RPG developed during the course by adding party management, Pokémon selection, catching mechanics, battle transitions, and clearer level-up feedback.

The main focus of the project was to practice:

* Turn-based battle systems
* Party and inventory management
* Game state transitions
* UI navigation
* Entity selection and validation
* Animation sequencing
* Player progression systems

Features

Level-Up Summary

Implemented a level-up menu that displays the Pokémon’s stat increases after gaining a level.

The menu shows the numerical changes applied to attributes such as:

* Health
* Attack
* Defense
* Speed

This provides clear feedback about how each Pokémon improves as it progresses.

Party Management System

Implemented a party menu that can be opened from the main map.

Opening the Party Menu

While in PlayState, pressing M opens the PartyState.

The menu displays:

* Current party members
* Pokémon images
* Current stats
* Health status

Pokémon Selection

Pressing Enter on a Pokémon marks it as the currently selected party member.

This selection system is used both outside battles and when choosing the next Pokémon during combat.

Fainted Pokémon

Fainted Pokémon:

* Appear greyed out in the party menu
* Cannot be selected
* Are excluded from valid battle choices

This provides immediate visual feedback while preventing invalid actions.

Pokémon Catching System

Implemented a catching mechanic using a Poké Ball.

Catch Conditions

A Poké Ball can only be thrown when the opposing Pokémon has:

* 25% health or less

This encourages the player to weaken an opponent before attempting to catch it.

Catch Animation

When a Poké Ball is thrown:

* The ball travels toward the opposing Pokémon
* A dedicated catching animation is played
* The battle resolves based on the catch attempt

This adds a recognizable Pokémon-style capture sequence to the battle system.

Battle Party Logic

Implemented party switching when a Pokémon faints during battle.

When the active Pokémon is defeated:

* The player is prompted to select another Pokémon
* The existing PartyState is reused
* Only living Pokémon are displayed as valid choices
* The selected Pokémon is sent into battle
* The battle continues without resetting

Reusing the same party interface keeps the implementation consistent across exploration and combat.

Technologies

* Lua
* LÖVE2D


Future Improvements

* Catch success probabilities based on health and Pokémon level
* Multiple Poké Ball types
* Pokémon storage system
* Status effects
* Experience sharing between party members
* Party reordering
* Healing items
* Additional battle animations
* Save-game persistence