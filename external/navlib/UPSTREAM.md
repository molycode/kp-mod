# Upstream

Source: https://github.com/molycode/Kingpin_NavLib - our fork of `drFredz/Kingpin_NavLib`, the
reconstruction of Xatrix's binary-only NavLib.

Commit: `c1719d18fde5da6ce08b84c185a47b0cdbbae44e`
Synced: 2026-09-17

The files here are a verbatim copy of that commit and carry no local edits. Fix navlib in the fork
first and re-sync, or the two silently diverge:

    git fetch https://github.com/molycode/Kingpin_NavLib main
    git archive FETCH_HEAD | tar -x -C external/navlib
