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
import "core:math"
import rl "vendor:raylib"

/* =========
Constants
=========*/
WINDOW_SIZE :: 1000
GRID_WIDTH :: 20
CELL_SIZE :: 16
CANVAS_SIZE :: GRID_WIDTH * CELL_SIZE

TICK_RATE :: 0.13
MAX_SNAKE_LENGTH :: GRID_WIDTH * GRID_WIDTH
IS_WASM :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32

// NOTES (1):
// Directly loading using rl.LoadSound doesn't work on web, propably because of relative path issues.
// It seems that only textures can be loaded from the assets folder.
// TODO: Ask Karl about this (or the discord)
CRASH_SOUND :: #load("../sounds/death.wav")
EAT_SOUND :: #load("../sounds/eat.wav")

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
  snake:          [MAX_SNAKE_LENGTH]Vec2i,
  snake_length:   int,
  tick_timer:     f32,
  move_direction: Vec2i,
  game_over:      bool,
  food_pos:       Vec2i,
  food_sprite:    rl.Texture,
  head_sprite:    rl.Texture,
  body_sprite:    rl.Texture,
  tail_sprite:    rl.Texture,
  eat_sound:      rl.Sound,
  crash_sound:    rl.Sound,
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
    run         = true,
    tick_timer  = TICK_RATE,
    // Textures
    food_sprite = rl.LoadTexture("assets/food_16.png"),
    head_sprite = rl.LoadTexture("assets/head_16.png"),
    body_sprite = rl.LoadTexture("assets/body_16.png"),
    tail_sprite = rl.LoadTexture("assets/tail_16.png"),
    // Sounds
    // eat_sound   = rl.LoadSound("sounds/eat.wav"), // See NOTES (1)
    // crash_sound = rl.LoadSound("sounds/death.wav"), // See NOTES (1)
    eat_sound   = rl.LoadSoundFromWave(rl.LoadWaveFromMemory(".wav", raw_data(EAT_SOUND), i32(len(EAT_SOUND)))),
    crash_sound = rl.LoadSoundFromWave(rl.LoadWaveFromMemory(".wav", raw_data(CRASH_SOUND), i32(len(CRASH_SOUND)))),
  }
  rl.SetSoundVolume(g_mem.eat_sound, 0.5)
  rl.SetSoundVolume(g_mem.crash_sound, 0.5)

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
  rl.InitWindow(WINDOW_SIZE, WINDOW_SIZE, "Snake HR")
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
    next_part_pos := g_mem.snake[0]
    g_mem.snake[0] += g_mem.move_direction
    head_pos := g_mem.snake[0]

    if head_pos.x < 0 || head_pos.y < 0 || head_pos.x >= GRID_WIDTH || head_pos.y >= GRID_WIDTH {
      g_mem.game_over = true
      rl.PlaySound(g_mem.crash_sound)
    }

    for i in 1 ..< g_mem.snake_length {
      cur_pos := g_mem.snake[i]

      if cur_pos == head_pos {
        g_mem.game_over = true
        rl.PlaySound(g_mem.crash_sound)
      }

      g_mem.snake[i] = next_part_pos
      next_part_pos = cur_pos
    }

    if head_pos == g_mem.food_pos {
      g_mem.snake_length += 1
      g_mem.snake[g_mem.snake_length - 1] = next_part_pos
      place_food()
      rl.PlaySound(g_mem.eat_sound)
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
    rl.ClearBackground({76, 53, 83, 255})
    rl.BeginMode2D(game_camera())
    rl.DrawTextureV(g_mem.food_sprite, {f32(g_mem.food_pos.x), f32(g_mem.food_pos.y)} * CELL_SIZE, rl.WHITE)

    for i in 0 ..< g_mem.snake_length {
      part_sprite := g_mem.body_sprite
      dir: Vec2i

      if i == 0 {
        part_sprite = g_mem.head_sprite
        dir = g_mem.snake[i] - g_mem.snake[i + 1]
      } else if i == g_mem.snake_length - 1 {
        part_sprite = g_mem.tail_sprite
        dir = g_mem.snake[i - 1] - g_mem.snake[i]
      } else {
        dir = g_mem.snake[i - 1] - g_mem.snake[i]
      }

      rot := math.atan2(f32(dir.y), f32(dir.x)) * math.DEG_PER_RAD

      source := rl.Rectangle{0, 0, f32(part_sprite.width), f32(part_sprite.height)}

      dest := rl.Rectangle {
        f32(g_mem.snake[i].x) * CELL_SIZE + 0.5 * CELL_SIZE,
        f32(g_mem.snake[i].y) * CELL_SIZE + 0.5 * CELL_SIZE,
        CELL_SIZE,
        CELL_SIZE,
      }

      rl.DrawTexturePro(part_sprite, source, dest, {CELL_SIZE, CELL_SIZE} * 0.5, rot, rl.WHITE)
    }

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

    score := g_mem.snake_length - 3
    score_str := fmt.ctprintf("Score: %v", score)
    rl.DrawText(score_str, 4, CANVAS_SIZE - 14, 10, rl.GRAY)

    rl.EndMode2D()
  }

  rl.EndDrawing()
} // draw

/* Shuts down game and frees memory
Called by the game_should_run proc in the api.odin file.
*/
shutdown :: proc() {
  rl.UnloadTexture(g_mem.head_sprite)
  rl.UnloadTexture(g_mem.food_sprite)
  rl.UnloadTexture(g_mem.body_sprite)
  rl.UnloadTexture(g_mem.tail_sprite)

  rl.UnloadSound(g_mem.eat_sound)
  rl.UnloadSound(g_mem.crash_sound)

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

/* Places the food in a random location
Returns:
  - position of the food
*/
place_food :: proc() {
  occupied: [GRID_WIDTH][GRID_WIDTH]bool

  for i in 0 ..< g_mem.snake_length {
    occupied[g_mem.snake[i].x][g_mem.snake[i].y] = true
  }

  free_cells := make([dynamic]Vec2i, context.temp_allocator)

  for x in 0 ..< GRID_WIDTH {
    for y in 0 ..< GRID_WIDTH {
      if !occupied[x][y] {
        append(&free_cells, Vec2i{x, y})
      }
    }
  }

  if len(free_cells) > 0 {
    random_cell_index := rl.GetRandomValue(0, i32(len(free_cells) - 1))
    g_mem.food_pos = free_cells[random_cell_index]
  }
} // place_food

/* Restarts the game and sets the initial state of the snake and food.*/
restart :: proc() {
  start_head_pos := Vec2i{GRID_WIDTH / 2, GRID_WIDTH / 2}
  g_mem.snake[0] = start_head_pos
  g_mem.snake[1] = start_head_pos - {0, 1}
  g_mem.snake[2] = start_head_pos - {0, 2}
  g_mem.snake_length = 3
  g_mem.move_direction = {0, 1}
  g_mem.game_over = false
  place_food()
} // restart
