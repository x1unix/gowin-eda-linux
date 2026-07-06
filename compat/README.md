# Gowin EDA OpenGL Support Fix

## Prerequesities

Install GCC or Clang compiler:

* **Arch Linux**: `sudo pacman -S base-devel`
* **Ubuntu / Debian / Linux Mint**: `sudo apt install build-essential`
* **Alpine**: `sudo apt add build-base`

## Usage

1. Run `cd compat && make`
2. Ensure that `libgowin-env-shim.so` is created.
3. Uncomment the `export GOWIN_OPENGL=1` in [`start-ide.sh`](../start-ide.sh) file.
