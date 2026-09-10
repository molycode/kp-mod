# kp-mod

The game library for *Kingpin: Life of Crime*, built from Xatrix's released SDK.

- **Windows** — `gamex86.dll`, via the `create-solution-vs20XX-win32.bat` scripts (requires CMake on `PATH`).
- **Linux** — `gamei386.so`, loaded by the retail `kingpin.x86`.

## Building on Linux

```bash
cmake --preset linux-gcc_16-debug
cmake --build --preset linux-gcc_16-debug
```

Presets: `linux-gcc_16-{debug,release}`, `linux-clang_22-{debug,release}`. Compiler roots come from
`KP_GCC_PATH` / `KP_CLANG_PATH`, set in the gitignored `CMakeUserPresets.json`. CMake 4.3.2 or newer
is required.

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

A GCC **Release** build also writes a stripped copy to `build/<preset>/src/ship/gamei386.so`. That
is the file to ship; the unstripped library beside it is the one to keep.

| | bytes |
|---|---|
| built (`-g`, full symbols) | 3,407,788 |
| shipped (`ship/`, stripped) | 1,358,452 |

Debug info is 54% of the built file, and stripping removes no code — only `GetGameAPI` is exported
either way. Both carry the **same GNU build id**, which is what makes the pair useful: a crash in a
shipped library symbolises against the unstripped copy, and savegames written by one load in the
other, since the savegame stamp is that build id (see `G_SaveStamp` in `g_save.c`).

Clang Release deliberately produces no `ship/` directory.

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
MSVC-only `navlib.lib` on Linux and is compiled with warnings suppressed, as external code.

*Kingpin: Life of Crime and related intellectual property remain the property of their respective
owners.*
