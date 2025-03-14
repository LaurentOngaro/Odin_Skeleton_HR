/*
This file is the starting point of your game.

Some important procedures are:
- init_window: Opens the window
- init: Sets up the game state
- update: Run once per frame
- should_close: For stopping your game when close button is pressed
- shutdown: Shuts down game and frees memory
- shutdown_window: Closes window

The procs above are used regardless if you compile using the `build_release`
script or the `build_hot_reload` script. However, in the hot reload case, the
contents of this file is compiled as part of `build/hot_reload/game.dll` (or
.dylib/.so on mac/linux). In the hot reload cases some other procedures are
also used in order to facilitate the hot reload functionality:

- game_memory: Run just before a hot reload. That way game_hot_reload.exe has a
      pointer to the game's memory that it can hand to the new game DLL.
- game_hot_reloaded: Run after a hot reload so that the `g_mem` global
      variable can be set to whatever pointer it was in the old DLL.

NOTE: When compiled as part of `build_release`, `build_debug` or `build_web`
then this whole package is just treated as a normal Odin package. No DLL is
created.
*/

package game

import "core:fmt"
import rl "vendor:raylib"

/* =========
Constants
=========*/
WINDOW_SIZE :: 1000
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE
TICK_RATE :: 0.13
IS_WASM :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

// NOTES (1):
// Directly loading using rl.LoadSound doesn't work on web, propably because of relative path issues.
// It seems that only textures can be loaded from the assets folder.
// TODO: Ask Karl about this (or the discord)
DEATH_SOUND :: #load("../sounds/death.wav")

/* =========
Structs and Enums
=========*/

Vec2i :: [2]int

/* Our game's state lives within this struct. In
order for hot reload to work the game's memory
must be transferable from one game DLL to
another when a hot reload occurs. We can do that
when all the game's memory live in here. */
Game_Memory :: struct {
  run:            bool,
  font:           rl.Font,
  player_pos:     Vec2i,
  score:          int,
  tick_timer:     f32,
  move_direction: Vec2i,
  game_over:      bool,
  player_texture: rl.Texture,
  death_sound:    rl.Sound,
}

/* =========
Variables
=========*/
// WARNING:
// If you put a global variable inside `game.odin` and hot reload then that global variable will be reset its initial state
// when the new game DLL is loaded.
// This can be fixed by only using global variables that are pointers to fields within `GameMemory`.
g_mem: ^Game_Memory
font: rl.Font // not used for the moment

/* =========
Procs
=========*/

/* Refresh the global variables by reading from the game memory.
This is called after a hot reload.
*/
refresh_globals :: proc() {
  // Here you can also set your own global variables. A good idea is to make
  // your global variables into pointers that point to something inside
  // `g_mem`.
  font = g_mem.font
} // refresh_globals

/* Allocate the GameMemory that we use to store our game's state
Called by the game_init proc in the api.odin file.
*/
init :: proc() {
  g_mem = new(Game_Memory)

  g_mem^ = Game_Memory {
    run            = true,
    tick_timer     = TICK_RATE,
    // Textures
    player_texture = rl.LoadTexture("assets/player.png"),
    // Sounds
    // death_sound = rl.LoadSound("sounds/death.wav"), // See NOTES (1)
    death_sound    = rl.LoadSoundFromWave(rl.LoadWaveFromMemory(".wav", raw_data(DEATH_SOUND), i32(len(DEATH_SOUND)))),
  }
  rl.SetSoundVolume(g_mem.death_sound, 0.5)

  restart()

  game_hot_reloaded(g_mem)
} // init

/* Initialize the raylib window and the audio device.
Called by the game_init_window proc in the api.odin file.
*/
init_window :: proc() {
  flags: rl.ConfigFlags

  when ODIN_DEBUG {
    flags = {.WINDOW_RESIZABLE, .VSYNC_HINT}
  } else {
    flags = {.VSYNC_HINT}
  }

  when IS_WASM {
    flags += {.WINDOW_RESIZABLE}
  }
  rl.SetConfigFlags(flags)
  rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Odin Skeleton HR")
  rl.SetWindowPosition(200, 200)
  rl.SetTargetFPS(500)
  rl.InitAudioDevice()
  when !ODIN_DEBUG && !IS_WASM {
    rl.ToggleBorderlessWindowed()
  }
  rl.SetExitKey(.KEY_NULL)
} // init_window

/* Simulation: Entities and physics updates
Called by the game_update proc in the api.odin file.
*/
update :: proc() {
  if rl.IsKeyDown(.UP) {
    g_mem.move_direction = {0, -1}
  }

  if rl.IsKeyDown(.DOWN) {
    g_mem.move_direction = {0, 1}
  }

  if rl.IsKeyDown(.LEFT) {
    g_mem.move_direction = {-1, 0}
  }

  if rl.IsKeyDown(.RIGHT) {
    g_mem.move_direction = {1, 0}
  }

  if g_mem.game_over {
    if rl.IsKeyPressed(.ENTER) {
      restart()
    }
  } else {
    g_mem.tick_timer -= rl.GetFrameTime()
  }

  if g_mem.tick_timer <= 0 {
    g_mem.player_pos += g_mem.move_direction

    if g_mem.player_pos.x < 0 || g_mem.player_pos.y < 0 || g_mem.player_pos.x >= GRID_WIDTH || g_mem.player_pos.y >= GRID_WIDTH {
      g_mem.game_over = true
      rl.PlaySound(g_mem.death_sound)
    }

    g_mem.tick_timer = TICK_RATE + g_mem.tick_timer
  }

  // Quit the game
  if rl.IsKeyPressed(.ESCAPE) {
    g_mem.run = false
  }
} // update

/* Rendering: Entities and UI Drawing
Called by the game_update proc in the api.odin file.
*/
draw :: proc() {
  rl.BeginDrawing()

  // DRAW the game
  // ------------
  {
    rl.ClearBackground({83, 83, 83, 255})
    rl.BeginMode2D(game_camera())

    source := rl.Rectangle{0, 0, f32(g_mem.player_texture.width), f32(g_mem.player_texture.height)}

    dest := rl.Rectangle {
      f32(g_mem.player_pos.x) * CELL_SIZE + 0.5 * CELL_SIZE,
      f32(g_mem.player_pos.y) * CELL_SIZE + 0.5 * CELL_SIZE,
      CELL_SIZE,
      CELL_SIZE,
    }

    rl.DrawTexturePro(g_mem.player_texture, source, dest, {CELL_SIZE, CELL_SIZE} * 0.5, 0, rl.WHITE)

    rl.EndMode2D()
  }

  // DRAW the UI
  // ------------
  {
    rl.BeginMode2D(ui_camera())

    // NOTE: `fmt.ctprintf` uses the temp allocator. The temp allocator is
    // cleared at the end of the frame by the main application, meaning inside
    // `main_hot_reload.odin`, `main_release.odin` or `main_web_entry.odin`.
    if g_mem.game_over {
      rl.DrawText("Game Over!", 4, 4, 25, rl.RED)
      rl.DrawText("Press Enter to play again", 4, 30, 15, rl.BLACK)
    }

    score_str := fmt.ctprintf("Score: %v", g_mem.score)
    rl.DrawText(score_str, 4, CANVAS_SIZE - 14, 10, rl.GRAY)

    rl.EndMode2D()
  }

  rl.EndDrawing()
} // draw

/* Shuts down game and frees memory
Called by the game_should_run proc in the api.odin file.
*/
shutdown :: proc() {
  rl.UnloadTexture(g_mem.player_texture)

  rl.UnloadSound(g_mem.death_sound)

  free(g_mem)
} // shutdown

/* Close the raylib window and the audio device.
Called by the game_shutdown_window proc in the api.odin file.
*/
shutdown_window :: proc() {
  rl.CloseAudioDevice()
  rl.CloseWindow()
} // shutdown_window

/* Create a camera for the game
Returns:
  - a camera
*/
game_camera :: proc() -> rl.Camera2D {
  return {zoom = f32(WINDOW_SIZE) / CANVAS_SIZE}
} // game_camera

/* Create a camera for the UI
Returns:
  - a camera
*/
ui_camera :: proc() -> rl.Camera2D {
  return {zoom = f32(WINDOW_SIZE) / CANVAS_SIZE}
} // ui_camera

/* Restarts the game and sets the initial state of the snake and food.*/
restart :: proc() {
  g_mem.player_pos = Vec2i{GRID_WIDTH / 2, GRID_WIDTH / 2}
  g_mem.score = 0
  g_mem.move_direction = {0, -1}
  g_mem.game_over = false
} // restart
