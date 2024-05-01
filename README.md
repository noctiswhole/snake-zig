# Snake with SDL2 + OpenGL in Zig

![Screenshot](https://raw.githubusercontent.com/noctiswhole/snake-zig/main/image.png?raw=true "Optional Title")

Made with Zig 0.12.0, SDL2, OpenGLES3

Depends on system installed SDL2.

Build with `zig build`

To build for KNULLI:

`zig build --search-prefix /path/to/buildroot/sysroot/usr/ -Dtarget=aarch64-linux-gnu -Dcpu=cortex_a53 -Doptimize=ReleaseSafe`

## Controls

Controls aren't remappable yet.

`A` Left

`S` Down

`D` Right

`W` Up

`R` Restart
