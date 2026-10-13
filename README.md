# Northvale Shooter (Godot 4.7)

A first-person fantasy shooter with an AK-47, magic, levels and talents across three locations.
Clear every enemy in a location and the next one loads automatically.

## How to run
1. Open Godot 4.7 → **Import** → choose `project.godot` in this folder.
2. Press **F5** (or the ▶ Play button at the top right).

## Controls
| Key | Action |
|---|---|
| W A S D / Mouse | Move / look |
| Left / Right mouse | Shoot (full-auto AK-47) / aim down sights |
| R | Reload (30-round magazine) |
| Shift / Space | Sprint / jump |
| **Q** (1) | Frost Arrow: freeze one enemy, frost damage over time |
| **E** (2) | Frost Nova: freeze everything around you |
| **F** (3) | Fireball: explodes and burns (unlocks at level 2) |
| **C** (4) | Renew: instant heal (level 2) |
| **G** (5) | Chain Lightning: jumps between enemies, stuns (level 3) |
| **V** (6) | Blink: teleport forward (level 4) |
| **T** (7) | Meteor: huge explosion where you aim (level 6) |
| **K** | Skill Book: spend talent points |
| M / Tab | Full map (shows every enemy) |
| Esc / P | Pause menu (Resume, Restart Location, Settings, Main Menu, Exit) |
| F11 | Toggle fullscreen |

## Levels and talents
- Kills give XP (bosses give double). Each level raises health and mana and gives **1 talent point**.
- Spend points in the Skill Book (**K**) to learn new skills or upgrade them (+30% damage per rank).
- Passive talents: Toughness (health), Arcane Mind (mana), Marksman (rifle damage), Frostbite (freeze time), Quick Hands (reload speed).
- Level, XP and talents carry over between locations (max level 15).

## Enemies
- Animated models: wolves, spiders, skeletons, ghouls, spirits, bandits, cultists, gnolls, yetis (harvest golems) and the demon warlord.
- **Abilities:** healers (Necromancer, Gnoll Shaman) heal hurt allies, Cultists shield allies, Necromancers raise skeletons, Spiders spit webs that slow you, Brutes, Golems and Captains slam the ground (step out of the red circle).
- **Bosses** charge, call down meteor strikes (with warning circles) and become **enraged** below 35% health.
- Red **explosive barrels** sit near enemy groups. Shoot them, and they chain-react.

## Settings (main menu or pause menu)
Fullscreen, VSync, Graphics quality (Low / Medium / High / Ultra: shadows, SSAO, reflections, grass density, view distance), mouse sensitivity, master / music / effects volume. Settings are saved automatically.

## Project layout
| Path | What it is |
|---|---|
| `scripts/levels/*.gd` | The three locations: layout, buildings, spawns, barrels, colors |
| `scripts/world.gd` | Loads a location, safe spawning, XP and drops, win / next location |
| `scripts/player.gd` | AK-47, recoil, reload, skills, XP / levels, footsteps |
| `scripts/skills.gd` | Skill and talent definitions, XP curve |
| `scripts/enemy.gd` | Enemy types, models and animations, AI, abilities |
| `scripts/explosion.gd`, `meteor.gd`, `barrel.gd`, `frost_bolt.gd` | Explosions, meteor strikes, barrels, spell projectiles |
| `scripts/hud.gd`, `settings_menu.gd` | HUD, action bar, XP bar, Skill Book, map, menus, settings |
| `scripts/game.gd` | Location order, music, sound bank, settings, input |
| `shaders/` | Terrain (with normal maps), sky, foliage, grass, realistic water, textures |

## Credits (all CC0 / public domain, no attribution required)
- **Music:** *The Old Tower Inn*, *The Bard's Tale*, *Minstrel Dance* by RandomMind; *Cathedral in the Forest* by congusbongus (opengameart.org)
- **Gun:** *The Free Firearm Sound Library* (opengameart.org)
- **Sound effects:** Kenney *Impact Sounds* and *RPG Audio*; *100 CC0 SFX* by rubberduck; *Male Grunt/Yelling sounds* by HaelDB; *Explosions* by EZduzziteh; ice sounds by artisticdude, bart and IgnasD; *Birds and Wind* by Spring Spring (opengameart.org)
- **Textures:** ambientCG.com (Grass004, Ground037, Ground048, Bark007, Rock030, PavingStones070, RoofingTiles006, Planks021)
- **3D models:** Quaternius via poly.pizza (Wolf, Spider, Skeleton ×2, Zombie, Orc, Hooded Adventurer, Ghost, Demon, Yeti)

## Quests, NPCs and fullscreen (latest update)
- Every location has 2-3 **quest givers** (yellow **!** = quest, **?** = turn in). Walk up and press **F** to talk; they speak their lines out loud. **X** is now Fireball.
- The next location unlocks when **all quests** in the current one are done. Quest types: kill, collect drops, gather glowing items, deliver to another NPC, and boss fights.
- Enemies **respawn** about 60 s after dying (bosses don't) and give up the chase about 40 m from home.
- 6 locations: Northvale, Darkwood, Goldfield Farms, **Frostpeak Pass**, **Emberforge Canyon**, **The Sunken Coast**. Look for hidden **treasure chests** near ruins, statues and camps.
- Voice lines are generated with Windows text-to-speech. Edit `data/dialogue.json`, then run `powershell -ExecutionPolicy Bypass -File tools\gen_voices.ps1 -Force`.
- **Fullscreen:** pressing F5 in Godot 4.4+ runs the game *inside the editor's Game tab*, where fullscreen is impossible. In the Game tab's toolbar, turn off "Embed Game on Next Play" (or use Editor Settings → Run → Window Placement → Game Embed Mode = Disabled). The game then opens in its own window, fullscreen by default (F11 toggles it).
## VesPerFPV, climbing, waypoints and the realism pass (newest update)
- **VesPerFPV** (FPV Pilot) stands just south of the abbey on Northvale. He speaks **Ukrainian** (English subtitles appear under his lines) and gives two quests: *Drone in the Treetops* (his drone is stuck in the Old Oak) and *Fresh Batteries* (take 4 batteries from bandits).
- **Climbing:** walk up to the rungs on the Old Oak and press **F**. **W/S** climb up and down, **A/D** move around the trunk, **Space** lets go. At the top you step onto a tree platform; press **F** there to climb back down.
- **Quest waypoint:** a gold diamond shows where to go next, with the distance. When the target is off-screen, an arrow on the edge of the screen points to it. A pulsing ring marks the same spot on the minimap and on the big map (**M**). The waypoint follows the quest you accepted most recently; with no active quest, it points to the nearest NPC with a **!**.
- **Bigger maps:** every location is now 560 x 560 m, with more camps, ruins and treasure.
- **New look:**
  - Trees are built from real leaf and needle textures, on bark with normal maps.
  - Scanned rocks, shrubs, ferns and fallen logs.
  - Buildings use brick, plaster and clay-tile textures with normal maps.
  - Frostpeak has snow on the ground and snow-dusted trees.
  - Quest givers and bandits use realistic human models. Bandits wear red bandanas and carry machetes.
- **VesPer's voice:** VesPer uses Piper TTS with the `uk_UA-ukrainian_tts` voice (speaker *mykyta*), pitched up in-game. To change his lines, edit `data/dialogue.json` and run `tools\gen_voices.ps1 -Force`. To use a real voice later, drop WAVs with the same names into `assets/voice/`.
- **Leaf textures:** `tools/make_leaf_cluster.ps1` regenerates `assets/textures/leaf_cluster.png` and `pine_cluster.png` from the ambientCG leaf set.

### Credits for this update
- **Piper TTS** (MIT) by the Rhasspy project; **ukrainian_tts** voice (CC0) by Yurii Paniv / robinhad.
- **Textures** (ambientCG, CC0): Bark014, Bricks066, Plaster001, RoofingTiles013A/014A, WoodSiding008, LeafSet017/024, Rock035, Snow006, Gravel023.
- **Scanned models** (Poly Haven, CC0): boulder_01, rock_moss_set_01, namaqualand_boulder_02, shrub_02, fern_02, dead_tree_trunk_02.
- **People models** (Quaternius via poly.pizza, CC0): casual, hoodie, man1, man2, business, farmer, worker, adventurer, woman, woman_casual, woman_dress.
## Horror update: interiors, chests, cutscenes, sounds (newest)
- **Story cutscenes:** each location opens with a narrated flyover (chapter title, landmarks, then down to you). Press **Space** to skip. In **Settings** you can turn cutscenes off and choose the narration language (**English** or **Ukrainian**; Ukrainian shows English subtitles underneath).
- **Story:** the *Grey Blight*, a curse that wakes the dead, spreads from chapter to chapter until its source on the Sunken Coast: Captain Bones' cursed gold.
- **Buildings you can enter:**
  - Every house has a door you open with **F**, glass windows with shutters, a beamed ceiling, a fireplace, a bed, a table and chairs, shelves and a lamp.
  - The abbey has pews, an altar, columns, stained glass and a double door.
  - The Goldfield barn has a hay loft you reach by a ramp. The windmill has a millstone room.
  - The lighthouse has a spiral stair up to a balcony.
- **Treasure chests:** iron-banded chests with a curved lid. The latch clicks, the lid creaks open, gold light spills out, and the loot flies to you with a loot list.
- **VesPerFPV on every level:** he gives a drone quest in each location: the Darkwood chapel, the Goldfield barn loft, the frozen lake, the Emberforge spires and the lighthouse balcony.
- **Sounds:**
  - Jumping is a cloth rustle and a breath. Landing and footsteps change with the surface (grass, snow, stone, wood).
  - Each pickup type has its own sound (coins, glass, electronics, bones).
  - Doors and chests creak. Creatures groan, roar, hiss and moan.
  - A horror ambience plays under every level, with distant screams.
- **Atmosphere:** thicker grey fog, washed-out colours and flickering lanterns.
- **High-poly creatures and characters:** see `DOWNLOADS.md`. Download the listed models into the `downloads` folder, and they will replace the current creatures, NPCs and gun.

### Credits for this update (all CC0)
Kenney (*Impact Sounds*, *RPG Audio*, *Interface Sounds*); artisticdude (*Zombies Sound Pack*); rubberduck (*80 CC0 creature SFX* 1 and 2); Ogrebane (*Monster Sound Pack*); qubodup (*Ghost Moans*); congusbongus (*Abandoned Passages* horror ambience); all from kenney.nl and opengameart.org.
## Big systems update: progression, gear, villagers, day/night, admin (newest)
- **Fixed:** the timber beam that blocked house doors is gone; floors are lower with a small ramp, and you can step up ledges and stairs.
- **Levels 1-50.** Each location has an enemy level range (Northvale 1-6, Darkwood 6-12, Goldfield 12-19, Frostpeak 19-27, Emberforge 27-36, Sunken Coast 36-45). Enemies further from the start are stronger. Their name colour shows how dangerous they are (grey = trivial, yellow = even, red/purple = much stronger). Much weaker enemies give little XP, so you may need to grind before moving on. 6% of enemies are **Elite** (gold name, glow, better loot).
- **Weapons and armor:** pistol, SMG, assault rifle, shotgun, sniper rifle, machine gun, crossbow, flamethrower, grenade launcher, and frost/fire/storm staffs (use mana). Helmet, body armor, gloves, boots and amulet. Five qualities (Common, Uncommon, Rare, Epic, Legendary) with random bonuses. Items drop from enemies, elites, bosses and chests.
- **Keys:** **I** inventory (drag items, right-click to equip), **1 / 2** or mouse wheel switch weapons, **L** flashlight.
- **Gold, trader, stash, saving:** every village has a trader's shop (buy and sell gear, buy ammo) with your personal stash chest. The game saves automatically (location start, every 2 minutes, menu, quit). Use **Continue** in the main menu.
- **Villages** in every location: a square with a well, market stalls and lamp posts; a tavern with an upstairs, a smithy, barracks, a shop, houses, a watchtower you can climb, stables, gardens. Plus crypts with treasure inside, ruined castles, fishing huts, a gatehouse, a sawmill and a granary.
- **Villagers** live there with daily routines: work in the day, chat on the square in the evening, go home and sleep in their beds at night. Press **F** to talk to them.
- **Town guards and wanted stars:** hurting a villager, a guard or a farm animal is a crime. Guards chase you (1-5 stars, more guards at higher stars). Break line of sight to lose them. Dying while wanted costs 10% of your gold.
- **Day and night:** 24-minute days with sunrise, sunset, stars and the moon. Nights are dark and more monsters roam (stronger, outside villages). Lanterns and windows glow.
- **Weather and life:** rain, thunderstorms and fog banks; deer, rabbits, crows and chickens; random events (caravan ambush, night raid on the village, a roaming dread elite, a wandering merchant).
- **Ukrainian:** choose Ukrainian under Settings > Language and every NPC speaks Ukrainian (English subtitles underneath) and all menus, HUD, items and quests are in Ukrainian.
- **Admin:** main menu > **Admin**, log in with **admin / admin**. You get a level select. In game, **F1** opens the admin panel (time of day, god mode, levels, gold, gear, teleports, weather, events, noclip) and **~** opens the console (type `help`, e.g. `time night`, `give sniper 4 30`, `level 25`, `spawn ghoul 5`).
- Loose duplicate sound files from the project root were moved into `_duplicate_sounds_backup` (ignored by Godot); delete that folder if you don't need it.
### Voices and performance (latest)
- **Ukrainian voices** now use the high-quality Piper voices from [piper1-gpl](https://github.com/OHF-Voice/piper1-gpl)'s voice list (rhasspy/piper-voices, Apache 2.0): **oleksa-high** (men, narrator), **tetiana-high** (women), **mykyta-high** (VesPer). Files are in `tools/voices/`; regenerate with `tools\gen_voices.ps1 -Force`.
- **Fixed:** some building parts disappeared after the speed-up (pieces with a unique material were removed instead of kept).
- **Occlusion culling:** walls and hills now hide what's behind them from the renderer (box occluders for big walls, a coarse terrain occluder). Distant idle enemies and far-away villagers also cost almost no CPU now.
## Editing locations yourself in the Godot editor
Every location has a hand-editable **extras scene** that is loaded on top of the generated level:
`scenes/levels/northvale_extra.tscn`, `darkwood_extra.tscn`, `farmlands_extra.tscn`, `frostpeak_extra.tscn`, `emberforge_extra.tscn`, `sunkencoast_extra.tscn`.

1. Open one in Godot (double-click it in the FileSystem panel). The generated level (terrain, roads, buildings, trees, landmark names, NPC spots and the player start) appears as a reference so you can place things against it. The reference is editor-only and never loads in the game.
2. Add things under the root node:
   - **Game objects:** add a child node of type **ExtraProp** (Add Child Node, then search "ExtraProp"). Pick its **Kind** in the Inspector: house, tavern, blacksmith, shop (comes with a trader and your stash), barracks (comes with guards), watchtower, stable, granary, chicken_coop, sawmill, fishing_hut, gatehouse, ruined_castle, crypt, well, market_stall, lamp_post, bench, cart, signpost, lantern, torch, campfire, tent, crate, barrel, hay_bale, haystack, fence, ruined_wall, climb_tree, treasure_chest, **enemy** (choose type, count, level, elite) or **animal**. In the editor it shows as a coloured box with its name; the yellow arrow is the front (door side). Move it, rotate it (Y), and the real thing is built there in the game. It always sits on the ground; raise it to lift it.
   - **Any model:** drag a `.glb` / `.gltf` from `assets/models` (or your own) into the scene. It gets collision automatically, and is lifted onto the ground if it's buried (both can be turned off on the root node).
   - Lights, particles, your own scenes: just add them.
3. Save (Ctrl+S) and play (F5).

Delete the `ExampleLantern_DeleteMe` node when you start. If you change a level script and want an updated reference, open `scenes/editor/make_reference.tscn` and press **F6** (Run Current Scene); it rebuilds the references and never overwrites your extras scenes. When you export the game, exclude `scenes/levels/reference/*` in the export filters (they're only for the editor, about 64 MB).

## Main menu and UI scale
- The main menu shows a live 3D village at dusk, styled after the location you last played: lanterns, embers, and the dead walking out of the forest. The menu has a gothic look; buttons glow like embers on hover, and Continue shows your location and level.
- **Settings > UI scale:** 50%-200%, or Auto. Applies to menus, HUD, inventory and dialogue. The main menu shrinks itself if it doesn't fit.

## The story, smarter villagers, kids and cinematics (newest)
- **Story:** you are a Ukrainian soldier. On a quiet dawn at the front you walked into the tree line, ate a glowing mushroom and woke up in Northvale with your rifle. The locals first treat you as an alien; over the six locations they learn technology from you (tech level 0-5) and you learn their magic. VesPerFPV has been here much longer than you, and he isn't from here either.
- **Opening cinematic (New Game):** a trench at dawn (sandbags, duckboards, a dugout, barbed wire, distant artillery, a drone overhead), the walk into the forest, the mushroom grove, the world bending, waking in a Northvale meadow. The soldier is a new model: pixel camo, helmet, plate carrier, rifle. **Space** skips. It only plays when *Story cutscenes* is on.
- **Ending cinematic:** after Captain Bones, VesPer tells his story at the lighthouse at sunset: a wheat field and his tractor, a mermaid in the river trading a glowing mushroom for his drone controller, and the moment he recognised your rifle. The same mushroom grows behind the lighthouse. Choose **[1] Stay** or **[2] Go home**; each choice has its own short ending, then the credits. Choosing Stay lets you keep playing: Continue picks up on the Sunken Coast.
- **Villagers have personalities:** brave, cowardly, gossip, grumpy, kind and superstitious.
  - When monsters come, **brave** villagers grab a pitchfork or an axe (muskets and rifles once they've learned from you) and fight. Monsters knock them out instead of killing them; they get back up about 40 s later.
  - **Cowards** and the **superstitious** scream, run home and shut the door. Everyone else runs to the guards. Afterwards they thank you.
  - They react to what you do: pointing a gun at them, firing nearby, being wanted.
- **Talking (F)** opens a topic menu: *The town*, *Rumours*, *About you*, *My weapon*, *Need help?*. All replies are voiced in English and Ukrainian. Greetings depend on personality, time of day, rain, whether you just saved the village, whether you're wanted, and what they think of you (the first time they talk about your strange weapon; that changes as their tech level grows). Kind villagers may give you a gift; grumpy ones won't.
- **Kids:** 2-4 per village. They play tag, kick a ball around the square (you can kick it too), chase chickens, follow you around asking about your gun and the world you came from, hide from monsters and go home at dusk. They can't be hurt; bullets and spells pass through them.
- **Technology spreads:** from Darkwood on, VesPer's drones circle over the villages. From Goldfield on there's a radio mast, and guards become **Musketeers** who shoot muskets. From Frostpeak on there are electric street lamps on wires with a chugging generator. From Emberforge on, the guards are **Riflemen**.
- **Magic lessons:** one quest per location ends with the quest giver teaching you a spell (free rank, no talent point needed): Renew (Northvale), Frostbite (Darkwood), Fireball (Goldfield), Frost Nova (Frostpeak), Meteor (Emberforge), Chain Lightning (Sunken Coast).
- **Flashlight:** press **L**. A reminder appears at dusk, and an "[L] Flashlight" label sits above the minimap whenever it's dark.
- **Sky:** a new sky shader with smooth, drifting, domain-warped clouds and round stars (no more blocky noise).
- **Fixed:** villagers no longer get wedged by their own doors (doors don't push anyone while they swing) and steer around furniture and obstacles.
- New voice lines live in `data/villager_talk.json` (villager talk) and `data/dialogue.json` (`vt_*`, `in_*`, `en_*`, `es_*`, `eh_*`). Regenerate with `tools\gen_voices.ps1`. Drone buzz, generator and artillery sounds are synthesized in `game.gd`, so nothing new had to be downloaded.

## Towns, travel, crafting and smarter NPCs (newest)
- **Smarter walking:** villages and towns get a baked navigation mesh, so villagers and kids walk around houses, fences, stalls and wells and through doorways instead of getting stuck.
  - **Fixed:** closing a conversation with Esc or F left a villager frozen in place.
  - **Fixed:** villagers stopped mid-walk after you talked to them.
- **Kids:** they move at a pace that fits their size, with no more foot sliding, spinning or flickering. Only one kid at a time tags along behind you, for about 15 seconds, then not again for a couple of minutes, and they chatter much less.
- **Dialogue:** a compact panel on the left. Replies are numbered (press **1-9** or click), and **Go away** is always the last option. Esc or F also leaves; villagers say a short goodbye.
- **Big towns:**
  - **Kingsreach**, the walled royal capital in Goldfield, with the King's castle and throne hall.
  - **Ravenmoor**, a market town in Darkwood.
  - **Saltmere**, a port town on the Sunken Coast.
  - Each has walls with gatehouses and guards, a big market square with a **notice board**, a weaponsmith, an armorer, an alchemist, a general trader with your stash, an inn, a temple (the priest can bless you: full health and mana) and a workshop with a workbench and a forge.
- **VesPer's portals:** once you bring VesPer his drone in Northvale, he builds a portal in the village where you arrive in every location. Use it (**F**) to travel anywhere.
  - The travel menu shows each location's level range and warns when it's deadly for you.
  - Every location remembers your quests between visits.
  - The story cutscene only plays the first time you arrive.
  - Finishing a location gives a reward and tells you where to go next; you travel when you're ready.
  - Dying puts you back at the portal (respawn) and costs 10% of your gold.
- **Travel quests** span several locations: the King's main line (A Royal Summons, The Grey Blight, Steel and Thunder, The King's Envoy, The Sunken Crown), courier jobs, escorting a pilgrim, and rare-material requests. All of them are voiced. The quest log and waypoint show the step; when it's in another location, the waypoint points to the portal.
- **Bounties:** town notice boards post kill bounties for gold and XP. You can hold up to three.
- **Difficulty:** monsters well above your level are deadly. At +10 levels they hit about 4x harder and take about a third of your damage; at +20 or more they one-shot you.
- **Crafting:**
  - **Materials:** monsters drop them (hides, bones, chitin, scrap, cloth, ectoplasm, essences...), you gather them from nodes with **F** (ore veins, herbs, glowcaps, logs, sulfur, clams on the beach), and you get them by salvaging gear (inventory, **Salvage mode**). Some only exist in one location: Star Iron and Frost Lotus (Frostpeak), Ember Core (Emberforge), Abyssal Pearl (Sunken Coast), Blight Dust (Darkwood).
  - **[U] Field kit**, anywhere: ammo packs and bandages.
  - **Alchemy table**: potions and gunpowder.
  - **Workbench**: frag grenades, landmines, sentry turrets, FPV strike drones and ammo crates.
  - **Forge** (in every smithy): weapons and armor of your level in the quality you choose (better quality costs essences; Legendary needs all three rare materials), plus upgrading an item's quality and rerolling its bonuses.
- **New keys:** **H** health potion (or bandage), **J** mana potion, **B** use gadget, **N** next gadget, **U** crafting.

## AI personalities in Northvale (newest)
The first location's people and monsters are driven by a local AI.
- **Ollama** runs the **Qwen3 8B** model on this PC.
- **The Python "brain"** (`brain/`) writes the lines.
- **SQLite** (`brain/northvale.db`) remembers.
- **Piper** (Ukrainian) and the Windows voices (English) speak every line.

**The AI is required to play.** The main menu shows the brain's status, and New Game / Continue wait until it says *AI brain ready*. The game starts Ollama and the brain by itself.

- **Characters** (edit them in `brain/personas.json`):
  - **Brother Aldric:** a secretive zealot who calls your rifle a devil's tool.
  - **Farmer Maybell:** an anxious mother of two who worries about everything.
  - **Sergeant Brannock:** a gruff veteran who talks soldier to soldier.
  - **VesPer:** a chubby, yawning teenager who plays piano and accordion, keeps trying to sell his drone, and always says he'll quit FPV. His body is wider now, in every location.
  - **Mobs:** swaggering Red Bandana thugs and their cruel Captain, cowardly kobold pranksters, and brainwashed cultists, ex-villagers who sometimes break through.
  - **Ashford villagers and kids:** they keep their personality types (kind, brave, coward, gossip, grumpy, superstitious).
- **Talking:**
  - Every quest giver, villager and kid answers in character, with 3 reply choices written by the AI. Quests, trading and *Go away* stay as buttons.
  - Quest offers and thank-yous are said in each character's own words, keeping the facts.
  - While someone "thinks", the game drops to 24 FPS so the AI gets the graphics card.
  - Greetings are written ahead while you walk up, so they're usually instant.
- **The valley talks:**
  - Villagers greet you as you pass, and chat with each other where you can overhear.
  - They react to bosses slain, quests done, crimes and raids.
  - Mobs shout in fights: spotting you, taunts, badly hurt, fleeing, a comrade down, the Captain's threats. These come from pools written ahead, so they're instant.
- **Memory:**
  - Each NPC remembers your conversations, summarised as you go.
  - Each has trust, fear and affection towards you, plus the village's overall opinion.
  - Events become gossip.
  - Each mob kind gets angry, then afraid, as you kill more of them.
  - A **New Game** wipes the memory; shout pools are kept.
- **Performance** (RTX 5060 8 GB):
  - 26 of the model's 36 layers run on the GPU, so the game keeps about 60–100 FPS.
  - Replies take about 8–15 s while playing.
  - The first start pre-writes about 110 shout pools, which takes about 15 minutes in the menu; after that they're saved.
  - Change `gpu_layers` in `brain/config.json`: higher is faster AI but less room for the game.
- **Comparing models:** `python brain/compare.py uk qwen3:4b qwen3:8b` runs the same Northvale moments through both. qwen3:4b was faster but its Ukrainian was often broken.
- **Sharing a build:** players need Python 3.12 and Ollama with `qwen3:8b` installed. The `brain` folder goes next to the exe, without `cache/`, `northvale.db` and `config.json`.

## Version control (git + GitHub)
- The project is a git repository, published to a **private** GitHub repo with GitHub Desktop. Open GitHub Desktop to see every change, commit, and **Push origin** to back it up online.
- **Not in git** (see `.gitignore`):
  - `.godot/`: Godot's cache, rebuilt on first open.
  - `build/`: exported games.
  - The source asset zips in the project root.
  - `downloads/` and `_duplicate_sounds_backup/`.
  - `tools/piper` and `tools/voices`: the Piper speech engine and its four Ukrainian voice models (about 400 MB; GitHub doesn't accept files over 100 MB).
- **Setting up a fresh copy** (another PC, or after a disk failure):
  1. Clone the repo in GitHub Desktop (*File → Clone repository*) and open the folder in Godot 4.7. The first import takes a few minutes.
  2. Only needed to make *new* voice lines (the existing ones are in `assets/voice`):
     - Put Piper (https://github.com/rhasspy/piper/releases, Windows build) into `tools/piper/`.
     - Put the uk_UA voices `tetiana`, `oleksa` and `mykyta` (high), plus `ukrainian_tts` (medium), from https://huggingface.co/rhasspy/piper-voices into `tools/voices/`.
  3. Only needed to export a build: install the Godot 4.7 export templates (*Editor → Manage Export Templates*).

## Making a release build (for sharing)
- The export templates for Godot 4.7 are installed, and `export_presets.cfg` has a **Windows Desktop** preset. The game has an icon (`icon.png` / `icon.ico`) and version `0.1.0` in Project Settings.
- **Rebuild:** Godot Editor → *Project → Export… → Windows Desktop → Export Project*. The output goes to `build/NorthvaleShooter/` (the `build` folder is ignored by Godot).
- **Command line:** `Godot_v4.7-stable_win64_console.exe --headless --path . --export-release "Windows Desktop" build/NorthvaleShooter/NorthvaleShooter.exe`
- Ship the whole folder: the exe, the `.pck`, and the two plugin DLLs (Terrain3D, GEQO). The v0.1.0 package with `How to play.txt` and a `Licenses` folder is `build/NorthvaleShooter-v0.1.0-windows.zip`; `build/GITHUB_RELEASE.md` has the text to paste on GitHub.
- For a new version, bump `config/version` and the preset's file and product version, re-export, and copy the `How to play.txt` and `Licenses` folder from the previous package.

## New monsters, smarter fights, swords, glass and a mirror (newest)
- **Golems:** the Harvest Golem (Goldfield) and Magma Golem (Emberforge) use a real animated golem model (walk, idle and four different punches). The Magma Golem has glowing lava cracks.
- **Dinosaurs** (animated Charcharosaurus model):
  - **Canyon Raptors** hunt Emberforge Canyon in packs of three, fast and biting.
  - **The Canyon Tyrant:** a giant boss in its bone-strewn nest east of the canyon (new landmark *Tyrant's Nest*, with eggs and rib cages). Scout Ryla first asks you to cull six raptors (*Raptor Cull*), then to kill the Tyrant (*The Canyon Tyrant*). The dialogue is voiced in English and Ukrainian.
  - **The Wandering Terror:** a rare giant dinosaur that roams the whole map in Darkwood, Goldfield, Frostpeak and the Sunken Coast, tinted for each place (swampy, golden, frosty, sea-green).
    - The ground shakes and a message warns you when it's near.
    - It walks from place to place, keeping away from towns and quest givers.
    - It comes back 12–18 minutes after being killed and drops lots of hide, fangs and bone.
- **Smarter fights** (GEQO addon, `scripts/tactics.gd`):
  - Casters and archers move to firing spots at range with a clear shot at you.
  - Wolves, raptors, gnolls, bandits, skeletons and spiders spread out and come at you from the sides instead of queueing up.
  - Some badly hurt bandits, kobolds, gnolls and cultists run to a spot you can't see, catch their breath, then come back.
  - GEQO scores the candidate spots; line of sight is checked with real rays. Without the addon the old AI is used.
- **Swords** (Arming Sword, `scripts/arms.gd`):
  - Guards and bandit captains fight with it; the King, Sergeant Brannock and Captain Ostrand wear one at the hip.
  - Crossed swords with shields hang in the castle hall and the barracks; the smithy's weapon stand and the forge hold real swords.
- **Glass** (Textured Glass Material Pack, `scripts/glass.gd`): house, shop and tavern windows have leaded, slightly refracting panes; the castle and temple have blue stained glass; tavern bottles are green glass.
- **Mirror** (Mirror3D addon): a tall gilded mirror by the castle door reflects the throne hall in real time. To save performance it only updates within 18 m, at most 30 times a second.
- **Kingsreach square:** a bronze hero statue on a stepped pedestal with four torches. It's the Super Human model, reduced from about 200k to 67k triangles.
- **Not used:** the animal pack and cow (no animations, and realistic style), and the Japan Young Woman scan (1.5 million triangles, no skeleton). Their zips are left untouched.

### Credits for this update
- **GEQO** by marrero171, MIT (`addons/geqo/LICENSE.txt`). **Mirror3D** by Joyless and Norodix, MIT (`addons/Mirror3D/LICENSE.md`).
- **Arming Sword** by Vairek, CC0. **Textured Glass Material Pack**, CC0 (`assets/textures/glass/LICENSE.txt`).
- **Golem**, **Charcharosaurus** and **Super Human** models: downloaded from Sketchfab; the zips had no licence file. Check each model's page for its licence and author credit.

## Sky3D, Terrain3D, props and music
- **Sky (Sky3D addon, `addons/sky_3d`):**
  - A physically based sky with a sun disk, a moon with phases, stars and the Milky Way, and drifting cumulus and cirrus clouds.
  - The game's own clock (1 real minute = 1 game hour) still runs everything: it feeds the hour to Sky3D, so sunrise is at 6:00 and sunset at 18:00 as before.
  - Rain and storms thicken the clouds; caves still darken the sun.
  - The code is in `World._build_sky3d()` and `DayNight._apply_sky3d()`.
- **Ground (Terrain3D addon, `addons/terrain_3d`):**
  - The ground is now drawn by Terrain3D: smooth detail far away, blended textures with normal maps, and mountains carrying on past the edge of the map.
  - Same heights, paths, paving, fields and rocky slopes as before. Collision and object placement still use the game's own heightmap, so nothing floats or sinks.
  - The packed textures are in `assets/terrain3d/`; the code is in `Terrain._build_terrain3d()`.
  - If the addon is removed, the old terrain is used automatically.
- **Props (Fantasy Props MegaKit, `scripts/prop_kit.gd`):**
  - Barrels, crates, beds, tables, chairs, benches and bookcases (filled with books and jars), plates, mugs, candles, chandeliers, chests and wall lanterns.
  - Shops: coins, scrolls and potions on the counter. Smithy: anvil on a log, whetstone, weapon stand, swords, axes and a shield. Market stalls and stall carts with fruit and vegetable crates.
  - Crafting stations: forge anvil, workbench, and an alchemy table with potions and a cauldron.
  - Camps: a cooking pot by the fire, plus bags, rope and buckets around it. The Kobold Mine has pickaxes, ropes, chains, metal torches and coins spilled by the chest.
- **Music:**
  - Music actually plays now. The RPG album is mastered 15–25 dB quieter than normal, so every track is levelled to the same loudness (`Game.MUSIC_LOUDNESS`), with a limiter on the music bus.
  - New tracks from the **Music Loops Mini Set**:
    - **Day and night playlists** per location mix the RPG tracks with Medieval Theme and Mystical loops, and rotate.
    - **Fights:** a random battle or epic percussion loop.
    - **Boss fights:** rock (Heart of Warrior, Unbreakable, Hard Rock…).
    - **Towns:** heroic themes (Dreams of Glory, Time of Heroes, Hope…).
    - **Caves:** mystical music.
    - **Location complete:** "Stay Strong" for 45 seconds.
- **Fixed:** monsters no longer spawn near quest givers.
  - Hostile spawns are kept at least 32 m from every quest NPC, town NPC and VesPer's portal (`World.clear_of_npcs`).
  - This covers level spawns, respawns, night packs, quest bosses, journey targets and road events.
  - Before, Farmer Maybell, Farmer Haldor, Millie and Gravekeeper Edwin stood among bandits, gnolls or skeletons.
- **Fixed:** the Kobold Mine had a rock you could walk through at the chamber exit. That was the inside of the chamber dome covering the tunnel; the dome now has an opening there.
- **Editor note:** to edit terrain or sky in the Godot editor, enable the Sky3D and Terrain3D plugins in *Project → Project Settings → Plugins*. The game itself doesn't need them enabled.

### Credits for this update
- **Sky3D** and **Terrain3D** by Tokisan Games (Cory Petkovsek) and contributors, MIT License (`addons/*/LICENSE.txt`).
- *The Milky Way panorama* by ESO/S. Brunier, licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), used in original and modified forms (Sky3D star map). Moon map © 2019 GPoSM, MIT. These are also shown in the ending credits.
- **Fantasy Props MegaKit** by Quaternius, CC0.
- **Music Loops Mini Set** by Andrew Sitkov, royalty-free for use in games (`assets/music/loops/LICENCE.pdf`; the music may not be redistributed on its own).

## Kobold Mine cave
- The Northvale **Kobold Mine** is now a real cave you can walk into: a timber-shored tunnel with rails and torches leads to a big domed chamber with glowing crystals, stalagmites and stalactites, iron ore veins, a treasure chest, and kobolds plus a geomancer.
- It gets dark inside (ambient light, sun and fog dim the deeper you go), so use the flashlight (**L**). The builder is reusable: `scripts/cave.gd` (`Cave.create(world, mouth, yaw, seed)`).
- **HUD:** the ammo panel has a fixed size in the bottom-right corner. Status text (reloading, low ammo, mana) has its own line, and long weapon names are cut with "…" instead of running off the screen.

## New art and music
- **Characters:**
  - Every human (villagers, kids, quest givers, traders, the King, guards, bandits, the soldier in the cinematics) now uses Quaternius' **Universal Base Characters** (male and female bodies, hairstyles, beards), animated with the **Universal Animation Library**.
  - Clothes are painted on by a shader per body part: shirts, short or long sleeves, trousers and boots in any colour; camo for the soldier.
  - Simple pieces are hung on the skeleton: skirts, coats, royal robes, aprons, belts, bracers, straw hats, and guard armor and helmets.
  - Outfits and colours vary per person. The code is in `scripts/people.gd`.
- **Buildings:**
  - Houses, shops, the tavern, barracks, temple, castle and the town buildings are built from the **Medieval Village MegaKit**: plaster or timber-framed walls (stone for the castle), arched kit windows and doors, round-tile roofs with gable fronts.
  - Doors, interiors and collision work as before. The code is in `scripts/kit_build.gd`.
- **Nature:** trees, bushes, plants, ferns and rocks come from the **Stylized Nature MegaKit**, tinted per location (autumn gold in Goldfield, dark in Darkwood, snowy in Frostpeak), plus flowers, grass clumps, clover, mushrooms and pebbles on the ground.
- **Music:** AlkaKrab's **Fantasy RPG Music Vol. 2**.
  - Every location has its own day, night and combat track, crossfading with what's happening.
  - Towns have their own theme.
  - Short stingers play on quest complete, location complete, death and portal travel.
  - The track choice is in `Game.MUSIC` (`scripts/game.gd`); the files are in `assets/music/rpg/`.
- **Performance:** kit pieces are merged per material like the other static geometry, and plants are multimeshes.
- **Fixed:** the kids' ball and VesPer's portal ring and drones were being frozen by the mesh batcher.

### Credits for this update
- **Universal Base Characters, Universal Animation Library, Medieval Village MegaKit, Stylized Nature MegaKit** by Quaternius (quaternius.com), CC0.
- **Fantasy RPG Music Vol. 2** by AlkaKrab. See *AlkaKrab Music License Info.pdf* in the original zip for the license terms.