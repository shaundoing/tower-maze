# Tower Maze

Single-file HTML5 game (`index.html`, ~2,800 lines): a marble-rolling maze where you descend a tower floor by floor. 2.5D isometric, canvas 2D, custom physics, no dependencies. Target platforms: itch.io (this build) now, Steam (future Three.js rebuild) later.

## Versioning workflow (important)

Every milestone is kept as a separately playable demo for a dev log:

1. Develop in the root `index.html`.
2. When a version is finished: `cp index.html versions/vN/index.html`, add an entry to `versions/index.html` (the launcher page), commit, `git tag vN`, then **push with tags automatically** (`git push --follow-tags`) — the user has asked for the push to happen without asking.
3. Never modify files under `versions/` except the launcher page — they are frozen snapshots.

Current latest: **v7**. Remote: `git@github.com:shaundoing/tower-maze.git` (SSH key `~/.ssh/id_ed25519_github`).

## Running / testing

- Served by systemd unit `tower-maze` at `http://127.0.0.1:8765` (also public via Cloudflare tunnel at tower-maze.purpleprawn.com). The server serves this directory live — no build step.
- Syntax check: extract the `<script>` body and run `node --check` on it.
- Behavioral testing: headless Chrome via CDP (`google-chrome --headless=new --remote-debugging-port=...`) using python3 + websockets; evaluate JS to teleport the ball / inspect `gs`, and capture screenshots. See git history for example drive scripts (they lived in /tmp).

## Code architecture (all in index.html)

- `CONFIG` (~line 340): all tunables — physics, iso view, brick/door, items.
- World is a flat x/y plane; rendering projects through `isoProject(wx, wy, wz)` with 90°-snap camera rotation (`gs.viewTarget`/`viewAngle`). Input is screen-space, converted via `screenDirToWorld`.
- `buildFloors()`: 4 floors defined proportionally to screen size (device-aware: phone 4×/2.5× screen, tablet/desktop 1.5×). Per floor: `tiles` (sparse map "col,row" → mud/ice/lava/pit), `movers`, `innerWalls` (some `material:'brick'`), `doors` (oneway/twoway/onetime), `bridges`, `launchers`, `ramps`, `pickups`.
- `gs` (game state, `createGS()`): ball (with z/vz for jumps), camera focus, per-floor puzzle/wall/door/bridge/pickup state, `dying` (death animation), `time`.
- `updatePhysics(dt)`: input → surface effects (mover/bridge/tile) → speed cap & friction → integrate → z-arc → wall/brick/door collisions → items → triggers → hole.
- Drawing: depth-sorted painter's algorithm — `drawFloor()` collects boxes (wall segments, doors, movers, launchers, posts...) + ball, sorts by `isoDepth`, draws; geometry hiding the ball renders translucent.
- Settings panel persists to localStorage key `tmSettings` (joy/tilt/bounce/sfx/music).
- Map overlay (`drawMapOverlay`) stays top-down and mirrors all features.

## Gotchas

- `/home/sean` once contained a stray git repo — always confirm `git rev-parse --show-toplevel` is this directory before git writes.
- Resize rebuilds floors but keeps `gs`; per-floor state arrays are index-keyed, so keep floor/wall/door ordering deterministic in `buildFloors()`.
- The Obsidian Git plugin and vault backup use separate HTTPS-token auth — unrelated to this repo's SSH auth; don't touch `~/.git-credentials`.

## Ideas backlog

See `Tower maze ideas 2.md` and `Game_Ideas.md` (game modes: burning building, zombies, burglar, intern). The Steam track (Three.js, free camera rotation, phone-yaw control) is deferred — keep floor/tile data structures renderer-agnostic.
