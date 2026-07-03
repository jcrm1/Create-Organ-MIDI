# Create-Organ-MIDI
Uses CC: Tweaked/ComputerCraft, Create, and ProjectRed to play MIDI files on a pipe organ in Minecraft.  
## Usage:
- Download the provided `midi organ clean` world
- Unzip it and add it to your Minecraft saves folder
- Run `midi.lua` on the turtle

There's some half-baked multi-computer support, which you can see by hooking up the computer closest to the turtle and running `receive.lua` while running `midi.lua` on the turtle. 

Only supports single-track 

sm64-merged.mid is modified from a file found on [BitMidi](https://bitmidi.com/super-mario-64-medley-mid), and the tracks were merged using [mergemid](https://github.com/m13253/midi-track-merge).

The provided world was made using Minecraft 1.21.1, CC: Tweaked 1.117.0, Create 6.0.9, [Create: Expanded Steam Whistles](https://github.com/Deanosaur75/ExpandedSteamWhistles) 0.3-1.21, ProjectRed Core 4.22.0-beta+33, and ProjectRed Transmission 4.22.0-beta+33.
