# Upstream

Source: https://github.com/molycode/Kingpin_NavLib - our fork of `drFredz/Kingpin_NavLib`, the
reconstruction of Xatrix's binary-only NavLib.

Commit: `d7b5474b896080edfda99ef417193375176a0480`
Synced: 2026-09-24

The files here are a verbatim copy of that commit and carry no local edits. Fix navlib in the fork
first and re-sync, or the two silently diverge:

    git fetch https://github.com/molycode/Kingpin_NavLib main
    git archive FETCH_HEAD | tar -x -C external/navlib
