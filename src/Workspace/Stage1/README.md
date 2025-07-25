# Stage&nbsp;1: SpongeBob’s Street

Welcome to the first stage of **Escape from Bikini Bottom**! This level takes place along SpongeBob’s colourful street, right outside his pineapple house.

## Theme
Players navigate through a neighbourhood full of quirky obstacles — dodging Gary’s slippery slime trails, leaping past falling mailboxes, and reaching a safe checkpoint inside the pineapple.

### Suggested Obstacles

| Obstacle | Description | Implementation Tips |
| --- | --- | --- |
| **Gary’s slime trails** | Thin strips of goo stretched across the path. Touching them kills players instantly. | Tag each slime part with the CollectionService tag `KillPart`, set a boolean attribute `IsKillPart` to `true`, or name it something containing “slime”. The `KillParts.server.lua` script automatically handles the deadly behaviour. |
| **Falling mailboxes** | Mailboxes look like safe platforms but will drop when stepped on. | Name these parts something containing `Mailbox` or tag them `FallingPlatform`. You can also set the `IsFallingPlatform` attribute to `true`. When touched, the script unanchors the part causing it to fall, then resets it after a short delay. |
| **Checkpoint inside the pineapple** | A safe respawn point hidden within SpongeBob’s pineapple house. | Place a `SpawnLocation` or `Part` inside the pineapple and name it something containing `checkpoint`, tag it with `Checkpoint`, or set the `IsCheckpoint` attribute. When a player touches it, their `RespawnLocation` is set to this part. |

## Folder Structure

Under `src/Workspace/Stage1/` you’ll find:

* **`KillParts.server.lua`** – watches for all kill parts in Stage 1 and connects the lethal touch behaviour.
* **`FallingPlatforms.server.lua`** – makes tagged mailboxes or platforms fall when touched and then reset.
* **`Checkpoint.server.lua`** – assigns players’ respawn locations when they touch a checkpoint part.
* **`README.md`** – this file, containing setup tips and placement suggestions.

## Tips for Building in Roblox Studio

1. **Place your models:** Create the physical geometry for Stage 1 in *Workspace > Stage1* within Studio. This might include roads, sidewalk, SpongeBob’s pineapple, fences, etc.
2. **Tag or name your parts:** Use the Tag Editor (Home › CollectionService › Add Tag) to tag kill parts as `KillPart`, falling parts as `FallingPlatform`, and checkpoints as `Checkpoint`. You can also use attributes (`IsKillPart`, `IsFallingPlatform`, `IsCheckpoint`) or part names containing the relevant keywords if you prefer.
3. **Anchor important structures:** Keep static structures anchored (houses, fences, ground). Only the falling mailboxes should be unanchored when triggered.
4. **Test with Rojo:** Run `rojo serve` in your project directory and open the corresponding Roblox Studio place. You should see Stage 1 appear in the Workspace tree with scripts automatically attached. When you step on slime or mailboxes, the scripts should respond accordingly.
5. **Iterate and decorate:** Add colourful decorations, models, or particle effects to bring Bikini Bottom to life. Feel free to adjust script delays or behaviours to tune the difficulty.

Happy building!  
