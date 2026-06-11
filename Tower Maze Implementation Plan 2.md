 Here is Claude's plan:
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌
 Tower Maze — "Ideas 2" Implementation Plan (staged versions for dev log)

 Context

 Tower maze ideas 2.md lists a batch of new features for the single-file canvas game index.html (~2,050 lines, custom physics, no engine). The user wants every game version
 preserved as a separately playable demo so a dev log can be filmed later.

 Key codebase facts (from exploration):
 - Git repo exists but has zero commits — current state must be committed first.
 - World is continuous: the 70px grid is visual only (drawFloor() ~line 1497); friction is uniform (CONFIG.friction, line 308). The tile ideas require a real tile data
 layer.
 - Floor size is hardcoded W*5 × H*3 in buildFloors() (lines 497–503); no device detection.
 - Settings: "cfg" button → #admin-panel with only joystick/tilt sliders, persisted to localStorage key tmSens (lines 1989–2030).
 - Audio is all procedural Web Audio (lines 357–454); volume via CONFIG.bounceVolume.
 - Walls are AABB rects (innerWalls + perimeter); doors exist only as the right-wall exit gap (lines 1417–1495).

 Versioning strategy (snapshot folders + git tags)

 The local server (python -m http.server on 8765) and the Cloudflare tunnel serve the whole project directory, so subfolders are instantly playable URLs.

 1. Bootstrap (do first): git add + initial commit of current state; tag v1; copy index.html → versions/v1/index.html; commit.
 2. Development always continues in the root index.html.
 3. When a version milestone is complete: copy root index.html → versions/vN/index.html, commit, tag vN.
 4. Add a small versions/index.html landing page linking to every version (handy for the dev log; updated each milestone).

 Result: tower-maze.purpleprawn.com/ is always latest; /versions/v2/ etc. stay frozen and playable forever.

 Version roadmap

 v2 — Sizing + Settings (small, low risk)

 Play area (buildFloors() lines 497–503):
 - Add device detection: tablet ≈ touch device with min(W,H) >= 600; phone = other touch devices; desktop keeps current behavior (or use phone values — confirm at build
 time, default: treat desktop like tablet).
 - Phone: fw = W*4, fh = H*2.5. Tablet: fw = W*1.5, fh = H*1.5.

 Settings panel (HTML lines 102–189, JS 1989–2030):

 Play area (buildFloors() lines 497–503):
 - Add device detection: tablet ≈ touch device with min(W,H) >= 600; phone = other touch devices; desktop keeps current behavior (or use phone values — confirm at build time, default: treat desktop like tablet).
 - Phone: fw = W*4, fh = H*2.5. Tablet: fw = W*1.5, fh = H*1.5.

 Settings panel (HTML lines 102–189, JS 1989–2030):
 - Rename the cfg button label to Settings.
 - Add three sliders: Bounce sensitivity (drives CONFIG.wallBounce), SFX volume (master gain multiplier applied in all play*Sound functions), Music volume (stored + wired to a musicGain variable; no music yet).
 - Extend the localStorage object (rename key to tmSettings, migrate from tmSens if present).

 v3 — Tile system: surfaces & hazards (the big structural change)

 Introduce a per-floor tile grid layer keyed to the existing 70px tileSize:
 - floor.tiles = sparse map "col,row" → type; default (absent) = grey/normal. Types: normal, mud, ice, lava, pit.
 - tileAt(x, y) lookup used in updatePhysics() (line 939):
   - Mud (brown): speed multiplier 0.8 and double friction decay.
   - Ice (pale blue): halve friction decay (friction exponent 0.5×).
   - Lava: death — flame-burst particle animation, ball becomes a small black ash pile.
   - Pit (black): death — ball shrinks/falls (scale + darken over ~0.6s).
 - Death dialog (per user decision): after the death animation, show an overlay with three buttons — Restart Floor (respawn at floor start, reset floor triggers), New Game (existing resetGame(), line ~688), Quit (return to a simple title/start
 screen — add a minimal one if none exists).
 - Moving tiles (dark grey platforms): per-floor list {x1,y1,x2,y2,w,h,speed,phase} oscillating between two points; ball on a moving tile inherits platform delta-movement per frame and gets 50% speed reduction (high friction). They span pit gaps.
 - Rendering: draw typed tiles before the grid in drawFloor(); lava gets an animated glow, ice a subtle sheen, pits solid black with inner shadow.
 - Redesign/extend the 4 floors (or add floor 5) to showcase each surface; update the minimap legend (drawMapOverlay(), line 1662).

 v4 — Walls & doors

 Brick walls (extend innerWalls entries with {material:'brick', hp:3}):
 - On ball impact above a speed threshold, decrement hp; draw progressive fracture cracks (3 visual stages); at 0 hp the wall segment is removed (does not repair). Persist per-floor in gs.
 - Grey walls and perimeter walls stay solid (perimeter breached only by doors).

 Doors (new floor.doors array on inner walls, reusing door-gap rendering style from lines 1417–1495):
 - One-way: passes ball only in its allowed direction; blocks reverse like a wall.
 - Two-way: needs an unlock each time — opens when ball touches it while a nearby trigger pad is active (reuse trigger-pad system, lines 636–685), then re-locks after passage.
 - One-time: works in either direction once, then seals permanently (visual change to "used").

 v5 — Items & bonuses

 - Wooden bridge: a tile strip over pit tiles with usesLeft (e.g. 3); small sign posts at each end render the remaining count; each full crossing decrements and increases a "worn" visual stage; at 0 the bridge collapses (tiles revert to pit) with a
 crack sound.
 - Launcher (movable item): draggable in-world object (drag with finger/mouse when ball not moving fast); when the ball touches its active face, the face springs outward (jack-in-the-box animation) and applies a strong impulse along its facing
 direction.
 - Ramp: tile object that, combined with launcher speed, lets the ball "jump" — while airborne (timer-based arc with shadow + scale), the ball ignores pit/lava tiles and walls below a height threshold, landing after a fixed distance scaled by entry
 speed.
 - Stronger Ball bonus: pickup (reuse trigger-pad visual language); while held, the next brick-wall impact destroys the segment in one hit; ball gets a glow.

 Files

 - index.html — all gameplay changes (single-file game).
 - versions/vN/index.html — frozen snapshots (new).
 - versions/index.html — version launcher page (new).
 - .gitignore — none needed (folder is clean).

 Verification (each version)

 1. systemctl status tower-maze / open http://127.0.0.1:8765 — play the root version with keyboard; confirm new features (e.g. v3: roll across mud/ice and feel the difference; touch lava → death dialog with 3 options).
 2. Open http://127.0.0.1:8765/versions/v1/ (and each prior version) — confirm old demos still play unchanged.
 3. Test on a phone/tablet via the Cloudflare tunnel URL to confirm the new play-area sizing and touch controls.
 4. git tag lists v1…vN; git log --oneline shows milestone commits.

 Execution order

 Bootstrap git + v1 snapshot → v2 → snapshot → v3 → snapshot → v4 → snapshot → v5 → snapshot. Each version is committed, tagged, and verified playable before starting the next.

