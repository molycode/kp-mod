# kp-mod

The *Kingpin: Life of Crime* game library, built from Xatrix's released SDK. Produces
`gamex86.dll` on Windows and `gamei386.so` on Linux, loaded by the retail `kingpin.x86`.

## Build

```bash
cmake --preset linux-gcc_16-debug
cmake --build --preset linux-gcc_16-debug
```

Presets: `linux-gcc_16-{debug,release}`, `linux-clang_22-{debug,release}`. CMake 4.3.2+ is required
(the system CMake is too old). Compiler roots come from `KP_GCC_PATH` / `KP_CLANG_PATH` in the
gitignored `CMakeUserPresets.json`; toolchains live in `cmake/toolchains/<platform>/<compiler>.cmake`
and flags in `cmake/compilers/`, matching the tge project layout.

## Rules

- **Ship GCC builds only.** Clang is a diagnostic second opinion, never the released artifact — it
  computes floats in SSE where retail and GCC use x87, so the two are not behaviourally
  interchangeable. See the README for the measurements. Build both; fix what either reports.
- **Never remove `-mstackrealign`.** The 1999 engine calls in on a 4-byte-aligned stack; without it
  an aligned SSE spill faults as `SIGSEGV` with `si_addr = 0x0`.
- `-fcommon` is required — the SDK headers define globals without `extern`.
- `src/game.map` exports `GetGameAPI` and nothing else; it is the Linux counterpart of `game.def`.
- `external/` is third-party and compiles with `-w`. Do not fix warnings there.

## Traps

- **Delete `build/` after editing a toolchain file.** `CMAKE_C_FLAGS_INIT` only seeds the cache on a
  tree's first configure, so an existing tree keeps the old flags and a flag change appears to have
  no effect.
- **Verify against both compilers.** Clang reports diagnostics GCC does not, and vice versa.
- **Never conclude a run passed from the absence of a crash.** A library whose `GetGameAPI` is
  hidden, or a build that failed and left a stale artifact in place, produces no crash and reads as
  success. Gate on a positive marker — the engine printing `Server Initialization`.
