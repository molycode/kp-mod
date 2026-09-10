# TODO

Work that is understood but parked, because it cannot be finished or verified in the environment
it was found in. Each item states what is known, what is only predicted, and what would settle it.

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
