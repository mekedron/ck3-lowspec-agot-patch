#!/usr/bin/env bash
# Diff this mod's shaders against the installed A Game of Thrones Workshop copy.
# Run it after an AGOT update: everything that is not one of the changes listed in the
# file banners is something AGOT changed and has to be carried over.
set -u
AGOT="${AGOT_DIR:-$HOME/.local/share/Steam/steamapps/workshop/content/1158310/2962333032}"
MOD="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
[ -d "$AGOT/gfx/FX" ] || { echo "AGOT not found at $AGOT (set AGOT_DIR)" >&2; exit 1; }
echo "AGOT $(grep -m1 '^version' "$AGOT/descriptor.mod")"
for f in pdxterrain.shader pdxwater.shader agot_vic3_fog_of_war.fxh; do
	echo "===== gfx/FX/$f"
	diff -u --strip-trailing-cr "$AGOT/gfx/FX/$f" "$MOD/gfx/FX/$f"
done
