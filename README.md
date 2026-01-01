# Dragon Flight Combat Game

A Roblox dragon riding game with combat mechanics, built with Rojo.

## Features
- Rideable dragons with flight controls
- Hunter NPCs that attack players
- Gold economy system
- Procedurally generated terrain
- Mount/dismount system
- Combat system with damage and health

## Setup

### Prerequisites
- [Rojo](https://rojo.space/) installed
- Roblox Studio

### Running Locally
1. Clone this repository
2. Navigate to the `src` directory
3. Run `rojo serve`
4. In Roblox Studio, use the Rojo plugin to connect to localhost:34872
5. Click Play to test the game

## Project Structure
```
src/
├── client/          # Client-side scripts (StarterPlayerScripts)
├── server/          # Server-side scripts (ServerScriptService)
├── shared/          # Shared modules (ReplicatedStorage)
│   ├── Beasts/      # Dragon classes
│   ├── Combat/      # Combat system
│   └── NPCs/        # Enemy NPCs
└── default.project.json  # Rojo project configuration
```

## Controls
- **E** - Mount/Dismount dragon
- **W/S** - Forward/Backward
- **A/D** - Turn
- **Space** - Fly up
- **Shift** - Fly down
- **Ctrl** - Boost

## Gamepad Controls
- **R2/L2** - Forward/Backward
- **Left Stick** - Turn
- **D-Pad Up** - Fly up
- **D-Pad Down** - Drop item / Fly down
- **Circle (B)** - Boost
- **Square (X)** - Dismount

## Development
Built with clean architecture focusing on modular systems and combat gameplay.
