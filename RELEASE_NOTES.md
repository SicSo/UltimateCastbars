## Version 0.10.0 - [15-03-2026]

### Added
- Full dynamic size for sync frames
- \[pName], \[tName], \[fName] tags 
- Added toggle for class colouring for names
- World latency tag \[wLat] (seconds) and \[wLAT] (ms)
- Option to use world latency instead of player latency for overlay and tags
- Added option to cap latency display to a max value (for both overlay and tags)
- Permanent background option
- Width and height control for text (manual or percentage-based)
- Print cast spell ID mode on cast (for spell ID identifying)

### User Interface
- Updated tick style
- Updated buttons style
- Updated sliders style
- Updated main window
- Updated group styles
- Added new colour picker
- Added UI scaling slider

### Changed
- Latency is computed based on the highest between world latency and computed latency

### Fixed
- OverlayPlayerCastingBarFrame was not being hidden on player unit
- In some vehicles, you become pet so PetCastingBar is used for player, the addon supports this now (hide pet in vehicle and show pet abilities as player)
- Copy profile was causing errors

---
