# kp-mod

The game library for *Kingpin: Life of Crime*, built from Xatrix's released SDK.

- **Windows** — `gamex86.dll`, via `create-solution-vs2022-win32.bat` (requires CMake on `PATH`).
- **Linux** — `gamei386.so`, loaded by the retail `kingpin.x86`.

> The `windows-msvc-*` presets are **not** a substitute for that batch file: they build 64-bit,
> which the i386 engine cannot load. See `todo.md`.

## Building on Linux

```bash
cmake --preset linux-gcc-debug
cmake --build --preset linux-gcc-debug
```

Presets: `linux-gcc-{debug,release}` and `linux-clang-{debug,release}`, which use whichever GCC or
Clang is on `PATH`. CMake 4.3.2 or newer is required.

To build against a toolchain that is not on `PATH`, point `KP_GCC_PATH` or `KP_CLANG_PATH` at its
installation root and add your own presets inheriting the ones above, in `CMakeUserPresets.json`
(gitignored).

> Changing anything in `cmake/toolchains/` requires deleting `build/` first. `CMAKE_C_FLAGS_INIT`
> only seeds the cache on a build tree's **first** configure, so an existing tree silently keeps the
> old flags.

## Ship GCC builds. Clang is a second pair of eyes.

**Released libraries must be compiled with GCC.** Clang is supported and should be built regularly,
but only as a diagnostic second opinion — never as the shipping artifact.

The reason is the floating-point model, which is not interchangeable between the two:

| build | x87 ops | SSE scalar float |
|---|---|---|
| retail 1999 `gamei386.so` | 30078 | 0 |
| GCC, `-m32` | 29452 | 404 |
| Clang, `-m32` | 578 | 16302 |

The retail library is pure x87. GCC on `-m32` defaults to `-mfpmath=387` and reproduces that model
almost exactly; Clang computes floats in SSE, and **cannot be moved off it** — `-mfpmath=387` is
rejected outright, because SSE2 is in Clang's i386 baseline. x87 keeps 80-bit intermediates where
SSE computes in 32-bit, so the two builds can and do diverge in trace, angle and physics results.
A GCC build is therefore the one that behaves like the original game.

Clang still earns its place: it reports diagnostics GCC does not, and has already caught real
defects here (including an operator-precedence bug in the auto-reload condition). Build both, fix
what either reports, and ship the GCC artifact.

### The shipping artifact

A GCC **Release** build is the artifact to ship, straight out of
`build/<preset>/src/gamei386.so`. There is no separate stripped copy and no post-build step: debug
info is a property of the configuration, so Release simply never generates any.

| configuration | flags | bytes |
|---|---|---|
| `Debug` | `-O0 -g` | — |
| `RelWithDebInfo` | `-O2 -g -DNDEBUG` | 3,305,456 |
| `Release` | `-O3 -DNDEBUG` | 1,489,928 |

Release keeps its **symbol table** (`.symtab`/`.strtab`, 127 KB of the total). That is deliberate:
it costs nothing at runtime and gives function names in a backtrace from the shipped library, which
is the one thing dropping `-g` would otherwise take away. Only `GetGameAPI` is ever exported —
`.symtab` is not part of the ABI surface, `game.map` decides that.

Reach for **`RelWithDebInfo`** when a bug needs hunting, not `Debug`: it is optimised, so it fails
the way the shipped build fails. `-O0` and `-O3` code misbehave differently.

Every configuration carries a **GNU build id**, which is what savegames are stamped with (see
`G_SaveStamp` in `g_save.c`) — so a save binds to one exact build and any rebuild invalidates it.

## Why `-mstackrealign` is mandatory

`kingpin.x86` is a 1999 binary that calls into this library on a **4-byte-aligned** stack. Modern
compilers assume the later 16-byte i386 ABI, so an aligned SSE spill (`movapd`) faults — a #GP
delivered as `SIGSEGV` with `si_addr = 0x0`, which reads misleadingly like a null dereference.

Both Linux toolchains therefore pass `-mstackrealign`, GCC included: GCC avoids the fault today only
because it defaults to x87, which is one vectorisation decision away from changing.

Arch flags were measured and deliberately left out. `-msse2` is a no-op — both compilers already
target it and produce a byte-identical library. `-mavx2` works, but only alongside `-mstackrealign`,
and it buys nothing on 1999 game logic while restricting the library to AVX2 CPUs.

## Third-party

`external/navlib` is [drFredz/Kingpin_NavLib](https://github.com/drFredz/Kingpin_NavLib), an
MIT-licensed reconstruction of the original `navlib`, vendored as a git subtree. It replaces the
SDK's binary-only `navlib.lib` on both platforms and is compiled with warnings suppressed, as
external code.

## Licensing

Four layers with different owners: the 1999 SDK (Xatrix/Interplay), id Software's Quake II, the
MIT NavLib reconstruction, and this repository's own changes. Only the last is licensed here.
Read [`LICENSE`](LICENSE) before redistributing anything built from this tree.
