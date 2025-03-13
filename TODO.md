# TO DO IN THIS FOLDER OR APP OR PACKAGE

## DOCUMENTATION

## DEVELOP BRANCH

### bugs

#### minor bugs

### todo

#### todo (later) / ideas

#### todo (later) performance

#### todo (not sure)

- move all the assets folders (sounds, fonts) into subfolder of the assets folder (as intially planned)
  - update the empsciptem compiler to allow the assets to be used from subfolders of the assets folder
  - update the code to load the assets from the subfolders of the assets folder
  - test the web version

## MASTER BRANCH

### known limitations

- for the web version to be compiled and run successfully:
  - the assets folder must contains only textures files with no subfolders (because it's embedded by the emscripten compiler)
  - all others assets folders must be at the root of the project and loaded by memory access (see how the sounds are loaded)
  - all the sounds must be ina WAV format (because it's the only format than can be loaded by memory access)

### known issues

### bugs

- the food can appear on a cell occupied by a part of the snake. Possible cause:
  - the position of the occupied cells is not correctly saved.
  - the get_available_cells() proc works bad.

#### minor bugs

### todo

## REGRESSION TESTS