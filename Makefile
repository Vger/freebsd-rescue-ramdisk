.PHONY: all makerescue loaderpatch install

DISKLABEL=rescue

all: makerescue loaderpatch

makerescue:
	./rescue_uzip.sh DESTDIR="$(DESTDIR)" DISKLABEL="$(DISKLABEL)"

loaderpatch:
	sed -E -e 's/@DISKLABEL/'$(DISKLABEL)'/' boot/loader.conf.rescue.template > boot/loader.conf.rescue

install: $(DESTDIR)/boot/rescue.uzip $(DESTDIR)/boot/lua/menu-rescue.lua $(DESTDIR)/boot/loader.conf.rescue $(DESTDIR)/boot/lua/local.lua

/tmp/rescueim/rescue.uzip:
	makerescue

$(DESTDIR)/boot:
	install -d $(.TARGET)

$(DESTDIR)/boot/rescue.uzip: /tmp/rescueim/rescue.uzip $(DESTDIR)/boot
	install -S $(.ALLSRC:[1]) $(.TARGET)

$(DESTDIR)/boot/lua:
	install -d $(.TARGET)

$(DESTDIR)/boot/lua/menu-rescue.lua: boot/lua/menu-rescue.lua $(DESTDIR)/boot/lua
	install -S -m 444 $(.ALLSRC:[1]) $(.TARGET)

$(DESTDIR)/boot/loader.conf.rescue: boot/loader.conf.rescue $(DESTDIR)/boot
	install -S -C -b -m 644 $(.ALLSRC:[1]) $(.TARGET)

$(DESTDIR)/boot/lua/local.lua: boot/lua/local.lua $(DESTDIR)/boot/lua
	./boot_lua_local.sh $(.ALLSRC:[1]) $(.TARGET)
