# TODO

Work that is understood but parked, because it cannot be finished or verified in the environment
it was found in. Each item states what is known, what is only predicted, and what would settle it.

## Windows: the MSVC presets build the wrong architecture

The library is loaded by a 1999 i386 engine, so it must be 32-bit. `create-solution-vs2022-win32.bat`
gets this right by passing `-A Win32` to the Visual Studio generator. The `windows-msvc-debug` and
`windows-msvc-release` presets do not: they use the Ninja generator, where the target architecture
comes from whichever developer prompt the build runs in, and their own `description` says to use the
**x64** Native Tools prompt. Following them produces a 64-bit `gamex86.dll` that the engine cannot
load.

`CMAKE_SYSTEM_PROCESSOR x86` in `cmake/toolchains/windows/msvc.cmake` does not help — with Ninja it
is informational and selects nothing.

Two ways to fix it, untested either way because Windows is not currently built:

- switch the presets to the Visual Studio generator and set `"architecture": { "value": "Win32" }`,
  matching what the `.bat` does; or
- keep Ninja and correct the description to the **x86** Native Tools prompt, accepting that the
  preset is then only as right as the shell it is run from.

The first is the safer of the two: it does not depend on the operator picking the right prompt.
Until one of them is done, the `.bat` script is the only correct Windows entry point, which is why
it is still in the tree.

## Windows: savegame build identity

The Linux half of this landed in `4a79272`. The Windows half is untouched, and Windows is not
currently built or played, so nothing here is urgent — but it should be done before anyone ships or
plays a `gamex86.dll`.

### Background

`g_save.c` stores every function pointer as a byte offset from `InitGame` and restores it as
`InitGame + offset`, so a savegame is readable only by the exact binary that wrote it. Loading one
into a different build sends every saved `think`, `touch`, `use` and `die` handler to a wild
address. On Linux this segfaulted on the first frame an entity thought; `G_SaveStamp()` now stamps
the ELF build id and the load is refused with a message instead.

`G_SaveStamp()` is the single point of change. Its `_WIN32` branch still returns `__DATE__`, which
is baked into this one file's object file and therefore survives any incremental build that does
not recompile `g_save.c`.

### 1. Remove `ReadLevel`'s base-address check — do this first

```c
#ifdef _WIN32
	if (base != (void *)InitGame)
		gi.error ("ReadLevel: function pointers have moved");
#endif
```

This is a load-address test, not a layout test, and it is wrong in both directions: it rejects a
relocated but identical build, and accepts a rebuilt one that happens to land at the same base.

It worked in 1999 only because the DLL had no ASLR. Measured from the retail
`_win32/main/gamex86.dll`:

```
ImageBase         : 0x20000000
DllCharacteristics: 0x0000      -> DYNAMICBASE off
Debug directory   : rva=0 size=0
```

A fixed, deliberately chosen image base meant `InitGame` had the same absolute address in every
process, so the check behaved as a same-binary test. This is also why the Linux port dropped it —
`.so` relocation made it useless there.

**Predicted, not verified:** `src/CMakeLists.txt` sets no `/DYNAMICBASE:NO`, and MSVC has defaulted
ASLR on since VS2012, so a modern `gamex86.dll` relocates every run and this check would fire on
*every* load — including a save written by the same binary minutes earlier. That would make Windows
unable to load any savegame at all. **Confirm this before doing anything else**: build the DLL,
save, restart the process, load.

Pinning the base with `/DYNAMICBASE:NO` would restore the 1999 behaviour, but it is not
recommended — base collisions still force relocation, and it still cannot catch a rebuild that
lands at the same base. The stamp supersedes the check; delete it.

### 2. Give `G_SaveStamp()` a Windows identity

| option | cost | semantics |
|---|---|---|
| PE `TimeDateStamp` via `__ImageBase` | ~10 lines, no new build flags | link timestamp; with `/Brepro` MSVC turns it into a hash of the output, matching the ELF build id's "an identical rebuild keeps existing saves loadable" |
| CodeView RSDS GUID + age | more parsing, needs `/Zi` and `/DEBUG` in **every** config | exact analogue of the ELF build id |

`TimeDateStamp` plus `/Brepro` is the recommended one. The Release config currently generates no
debug directory at all, so the GUID route means adding debug info to Release first.

No SDK source includes `windows.h` today. Either pull it in behind `WIN32_LEAN_AND_MEAN` inside the
`_WIN32` block, or read the two fields by offset from `extern char __ImageBase` (`e_lfanew` at
`0x3c`, `TimeDateStamp` at `e_lfanew + 8`) and add no header at all.

### 3. Verify

There is no automated harness for this on Windows. The Linux equivalent drove the retail engine
through a scratch mod directory (`+set game savetest`) with a generated `.cfg` of `wait` lines
around `save` and `load`, which kept the playable install untouched. The two cases that matter:

- a save written by a different build must be refused with a message and no crash,
- a save written by the same build must still load.

## Windows: navlib is built from source but has never been compiled there

`src/navlib/navlib.lib` is gone. Both platforms now compile the reconstruction in `external/navlib`
and link it as `KpNavLib`. **Linux is verified byte-identical across this change** — `.text` is
unchanged and the stripped library differs only in its build id — but **no part of the Windows path
has been built**, because Windows is not currently built or played.

### Why the blob went

It was the SDK's binary-only NavLib: Xatrix never released its source, which is why
[drFredz/Kingpin_NavLib](https://github.com/drFredz/Kingpin_NavLib) exists. Keeping it meant the two
platforms ran different navigation code, and it was the only piece of Xatrix object code in the
tree.

`/NODEFAULTLIB:libc.lib` was removed with it. That flag existed solely to suppress the blob's VC6
CRT reference — the archive carries `-defaultlib:LIBC -defaultlib:OLDNAMES` — and nothing else in
the tree pulls `libc.lib`.

### Predicted, not verified — confirm in this order

1. **MSVC compiles `external/navlib`.** Likely: `g_nav_io.c` already guards `<direct.h>` behind
   `#ifdef _WIN32`, `external/CMakeLists.txt` already guards `-fcommon` behind `if(NOT MSVC)`, and
   upstream ships a Code::Blocks project claiming Visual C++ 6.0 compatible settings. None of that
   has been run through a compiler.
2. **The link resolves.** On Linux it does — `KpNavLib` is an OBJECT library, so nothing is dropped
   lazily and every symbol `src/` references is satisfied. MSVC should behave the same, but the
   1999 blob may have exported symbols the reconstruction does not.
3. **`/NODEFAULTLIB:libc.lib` really is dead.** If the link fails looking for `libc.lib`, something
   else is dragging it in and the flag goes back.
4. **Navigation behaves.** Loading a `.nav` file and watching monsters path is the real test; a
   clean link proves only that the symbols exist.

Build via `create-solution-vs2022-win32.bat`, not the `windows-msvc-*` presets — see the
architecture item above.

### If it cannot be made to work

The blob is recoverable from this repository's history (`git show 3c8a724^:src/navlib/navlib.lib`)
or from `kpsdk.zip`. Restoring it means restoring `/NODEFAULTLIB:libc.lib` and re-guarding
`add_subdirectory(external)` to Linux — but prefer fixing the reconstruction, so that both platforms
run the same navigation code.
