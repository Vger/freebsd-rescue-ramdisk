#!/bin/sh
SRC="$1"
DEST="$2"
if [ -z "$SRC" ]; then
	SRC="./boot/lua/local.lua"
fi
if [ -z "$DEST" ]; then
	DEST=/boot/lua/local.lua
fi
got_dest=0
if [ -s "$DEST" ]; then
	if grep -q -E '\brequire[[:space:](]*(["'\'']|\[\[)menu-rescue(["'\'']|\]\])' "$DEST"; then
		# We're done, seems like target file does not need update.
		exit 0
	fi
	got_dest=1
fi
echo 'require("menu-rescue")' > "${SRC}.new" || exit $?
if [ $got_dest -eq 1 ]; then
	cat "$DEST" >> "${SRC}.new" || exit $?
fi
mv -f "${SRC}.new" "${SRC}" || exit $?
install -S -b -m 644 "$SRC" "$DEST"
