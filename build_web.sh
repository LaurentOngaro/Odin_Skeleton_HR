#!/bin/bash -eu

# This script builds the Odin project for the web platform using Emscripten.
# It sets up the environment, compiles the Odin code to WebAssembly,
# and generates the necessary HTML and JavaScript files to run the application in a web browser.

# Point this to where you installed emscripten. Optional on systems that already
# have `emcc` in the path.
EMSCRIPTEN_SDK_DIR="$HOME/repos/emsdk"
OUT_DIR="build/web"
SRC_DIR=source

OUTPUT_FILE=$OUTPUT_FILE
# temporary fix for a bug in odin wasm
OUTPUT_FILE=game$OUTPUT_FILE

mkdir -p $OUT_DIR

export EMSDK_QUIET=1
[[ -f "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh" ]] && . "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh"

# Note RAYLIB_WASM_LIB=env.o -- env.o is an internal WASM object file. You can
# see how RAYLIB_WASM_LIB is used inside <odin>/vendor/raylib/raylib.odin.
#
# The emcc call will be fed the actual raylib library file. That stuff will end
# up in env.o
#
# Note that there is a rayGUI equivalent: -define:RAYGUI_WASM_LIB=env.o
odin build "$SRC_DIR/main_web" -target:js_wasm32 -build-mode:obj -define:RAYLIB_WASM_LIB=env.o -define:RAYGUI_WASM_LIB=env.o -vet -strict-style -out:$OUT_DIR/game

ODIN_PATH=$(odin root)

cp $ODIN_PATH/core/sys/wasm/js/odin.js $OUT_DIR

files="$OUT_DIR/$OUTPUT_FILE ${ODIN_PATH}/vendor/raylib/wasm/libraylib.a ${ODIN_PATH}/vendor/raylib/wasm/libraygui.a"

# index_template.html contains the javascript code that calls the procedures in
flags="-sUSE_GLFW=3 -sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sASSERTIONS --shell-file $SRC_DIR/main_web/index_template.html --preload-file assets"

# For debugging: Add `-g` to `emcc` (gives better error callstack in chrome)
emcc -o $OUT_DIR/index.html $files $flags

rm $OUT_DIR/$OUTPUT_FILE

echo "Web build created in ${OUT_DIR}"
