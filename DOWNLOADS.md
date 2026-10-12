# Models to download (for the horror / high-poly update)

Put every file into the `downloads` folder in the project (`Shooter\downloads\`), keeping the
file names the sites give you. Make a subfolder per item when the download is a zip (just unzip
it there). When you're done, tell me and I'll wire everything in.

All of these are free. Sketchfab models are **CC Attribution** (I add the credits to the README),
Mixamo is free with an Adobe account and royalty-free for games.

---

## 1. Sketchfab (log in, open the link, click **Download 3D Model**, choose **glTF**)

| Save as folder | Model | Used for | Link |
|---|---|---|---|
| `downloads/spider` | Giant Huntsman Spider (34k polys) | Darkwood giant spiders, Sunken Coast crabs (re-tinted) | https://sketchfab.com/models/6b46820aba4e4f7f82c1fa534e61724f |
| `downloads/helldemon` | HellDemon Reborn (74k polys, 7 animations) | Emberforge demons + Pyrax boss | https://sketchfab.com/models/43e163c12f304a35b1f85476ca2549f6 |
| `downloads/yeti` | the yeti (20k polys, 43 animations) | Frostpeak yetis + Frostmaw boss | https://sketchfab.com/models/fb3b45079dfc4e94935b84725e30f100 |
| `downloads/dogman` | Burnt Dogman (7 animations) | Zombie hounds (replace wolves) + Emberforge hellhounds | https://sketchfab.com/models/bcbf2bc05c834bda934e93706e58c581 |
| `downloads/wraith` | Wraith (42k polys) | Wraiths / ghosts / frost wraith / sea witch | https://sketchfab.com/models/ac1cc4d4f2344633940a3d9e44224ab6 |
| `downloads/fps_arms` | FPS AK-74m animations (40k polys, 8 animations) | New first-person arms + rifle | https://sketchfab.com/models/94be8385c402474cacd39bc096c6ca14 |

Backup for the arms if the first one won't download: **AK-74M Animations (BLENDER)**, 13 animations:
https://sketchfab.com/models/effd52406532433eaac9454740572c57 (save as `downloads/fps_arms2`).

---

## 2. Mixamo (https://www.mixamo.com, log in with a free Adobe account)

### 2a. Characters (Characters tab)
Click a character, then **Download** with these settings:
**Format: FBX Binary (.fbx) · Pose: T-pose**. Save into `downloads/mixamo/characters/`.

Horror creatures (search these words, pick the ones that look best to you):
- `zombie`: **6 different zombies** (men and women, different clothes). They become infected villagers, farmers, bandits, frozen corpses and drowned sailors.
- `mutant`: **Mutant** (big hulking monster, Northvale/Farmlands boss).
- `warrok`: **Warrok W Kurniawan** (brute / gnoll replacement).
- `parasite`: **Parasite L Starkie** (fast crawler / kobold replacement).
- `skeleton`: **Skeletonzombie T Avelange** (Darkwood skeletons, Grave Lord boss).

Quest-giver NPCs (realistic people), about 12, pick a mix:
- 1 **young guy / teen in casual clothes** (the new VesPer body; I put his photo face on it)
- 2-3 **older men** (priest, gravekeeper, fisherman, farmer)
- 3-4 **women** (farmer, herbalist, lighthouse keeper, scout, miller)
- 2 **soldier / knight / guard** types (sergeant, captain, outpost commander)
- 1 **robed / mage-looking** character (archmage)

### 2b. Animations (Animations tab)
Pick **any one** zombie character first (the animations work on all of them), then for each
animation below click **Download** with:
**Format: FBX Binary · Skin: Without Skin · Frames per second: 30 · Keyframe reduction: none**.
Tick **In Place** where that box appears. Save into `downloads/mixamo/animations/`.

Zombies / mutants:
`Zombie Idle`, `Zombie Walk`, `Zombie Running`, `Zombie Attack`, `Zombie Punching`, `Zombie Biting`,
`Zombie Scream`, `Zombie Dying`, `Zombie Reaction Hit`, `Zombie Crawl`, `Running Crawl`,
`Mutant Idle`, `Mutant Walking`, `Mutant Run`, `Mutant Swiping`, `Mutant Roaring`, `Mutant Dying`,
`Mutant Jump Attack`

People (for NPCs):
`Idle`, `Breathing Idle`, `Talking`, `Waving`, `Thinking`, `Standing Greeting`

If a name doesn't exist exactly, take the closest one. The names don't have to match.

---

## Folder layout when finished

```
Shooter/
  downloads/
    spider/  helldemon/  yeti/  dogman/  wraith/  fps_arms/
    mixamo/
      characters/   (≈22 .fbx files)
      animations/   (≈24 .fbx files)
```
