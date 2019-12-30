# freebsd-rescue-ramdisk
FreeBSD rescue ramdisk support in boot menu.

Typical installation:
```
$ make
(become root)
# make install
```

You can change the default ufs label of the generated
ramdisk by using DISKLABEL variable in the make step, e.g.
```
$ make DISKLABEL=fbsd12rescue
(become root)
# make install
```
