package game

import rl "vendor:raylib"

/* Allocates the GameMemory that we use to store
our game's state. We assign it to a global
variable so we can use it from the other
procedures. */
@(export)
game_init :: proc() {
  init()
}

/* Initializes the raylib window and the audio device. */
@(export)
game_init_window :: proc() {
  init_window()
}

/* Simulation and rendering goes here. Return
false when you wish to terminate the program. */
@(export)
game_update :: proc() {
  update()
  draw()
}

/* Returns true if the game should continue running. */
@(export)
game_should_run :: proc() -> bool {
  when ODIN_OS != .JS {
    // Never run this proc in browser. It contains a 16 ms sleep on web!
    if rl.WindowShouldClose() {
      return false
    }
  }
  return g_mem.run
}

/* Called by the main program when the main loop
has exited. Clean up your memory here. */
@(export)
game_shutdown :: proc() {
  shutdown()
}

/* Close the raylib window and the audio device */
@(export)
game_shutdown_window :: proc() {
  shutdown_window()
}

/* Returns a pointer to the game memory. When
hot reloading, the main program needs a pointer
to the game memory. It can then load a new game
DLL and tell it to use the same memory by calling
game_hot_reloaded on the new game DLL, supplying
it the game memory pointer. */
@(export)
game_memory :: proc() -> rawptr {
  return g_mem
}

/* Returns the size of the game memory struct. */
@(export)
game_memory_size :: proc() -> int {
  return size_of(Game_Memory)
}

/* Used to set the game memory pointer after a
hot reload occurs. See game_memory comments. */
@(export)
game_hot_reloaded :: proc(mem: rawptr) {
  g_mem = (^Game_Memory)(mem)
  refresh_globals()

}

/* Forces the game to reload. */
@(export)
game_force_reload :: proc() -> bool {
  return rl.IsKeyPressed(.F5)
}

/* Forces the game to restart. */
@(export)
game_force_restart :: proc() -> bool {
  return rl.IsKeyPressed(.F6)
}

/* In a web build, this is called when browser changes size.
Remove the`rl.SetWindowSize` call if you don't want a resizable game. */
@(export)
parent_window_size_changed :: proc "c" (w, h: int) {
  rl.SetWindowSize(i32(w), i32(h))
}
