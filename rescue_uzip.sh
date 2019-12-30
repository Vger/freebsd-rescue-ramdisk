#!/bin/sh

DESTDIR=""
DISKLABEL="rescue"
PREPAREDIR=/tmp/rescue
IMAGEDIR=/tmp/rescueim

while [ $# -gt 0 ]; do
	case "$1" in
		DESTDIR=*)
			DESTDIR="${1#DESTDIR=}"
			;;
		DISKLABEL=*)
			DISKLABEL="${1#DISKLABEL=}"
			if [ "x$(echo "$DISKLABEL"|tr -d '[:alnum:]')" != "x" ]; then
				echo "Disklabel '$DISKLABEL' is invalid"
				exit 1
			fi
			echo "Using disklabel: $DISKLABEL"
			;;
	esac
	shift
done

if [ -d "${DESTDIR}/rescue" ]; then
	RESCUEDIR="${DESTDIR}/rescue"
else
	RESCUEDIR="/rescue"
fi
if [ -d "$PREPAREDIR" ]; then
	echo "Directory $PREPAREDIR already exists, not overwriting!"
	exit 1
fi
mkdir -p "${PREPAREDIR}/rescue" || exit 1
mkdir -p "$IMAGEDIR" || exit 1
tar -c -C "$RESCUEDIR" -f - . | tar -C "${PREPAREDIR}/rescue" -x -f - || exit 1

cd "$PREPAREDIR" || exit 1
tmpfs_ko=""
if [ -d "${DESTDIR}/boot/kernel" ] && [ -x "${DESTDIR}/boot/kernel/tmpfs.ko" ]; then
	tmpfs_ko="${DESTDIR}/boot/kernel/tmpfs.ko"
elif [ -d "/boot/kernel" ] && [ -x "/boot/kernel/tmpfs.ko" ]; then
	tmpfs_ko="/boot/kernel/tmpfs.ko"
fi
if [ -n "$tmpfs_ko" ]; then
	mkdir -p boot/kernel || exit 1
	cp "$tmpfs_ko" boot/kernel/tmpfs.ko || exit 1
fi

mkdir dev || exit 1
mkdir tmp || exit 1
mkdir etc || exit 1
mkdir -p usr/sbin || exit 1

cat > etc/rc << EOF
#!/rescue/sh
HOME=/
PATH=/rescue:/usr/sbin
export HOME PATH
/rescue/sh
EOF

cat > usr/sbin/enterroot << EOF
#!/rescue/sh
if [ \$# -gt 0 ]; then
	/rescue/kenv vfs.root.mountfrom="\$1"
fi

newroot=\$(/rescue/kenv vfs.root.mountfrom 2>&-)
if [ -z "\$newroot" ]; then
	echo "vfs.root.mountfrom is not set"
	exit 1
fi
if [ "\$newroot" = "ufs:ufs/$DISKLABEL" ]; then
	echo "vfs.root.mountfrom is still pointing at ufs:/ufs/$DISKLABEL,"
	echo "so there is little point in entering that root."
	exit 1
fi
if [ -d /boot/kernel ] && [ -x /boot/kernel/tmpfs.ko ]; then
	/rescue/kldstat -m tmpfs 2>&- || /rescue/kldload tmpfs || exit \$?
fi
/rescue/reboot -r
EOF
chmod 755 usr/sbin/enterroot

ln -s "/rescue" "bin"
ln -s "/rescue" "sbin"

mtree -c -R nlink,size,time -p "$PREPAREDIR" | sed -E -e 's/\<([gu]id)=[0-9]+\>/\1=0/g' | makefs -o label="$DISKLABEL" "${IMAGEDIR}/rescue.ufs" - && \
mkuzip -L -o "${IMAGEDIR}/rescue.uzip" "${IMAGEDIR}/rescue.ufs" && \
rm -f "${IMAGEDIR}/rescue.ufs"
exitcode=$?

rm -rf "$PREPAREDIR"

exit $exitcode
