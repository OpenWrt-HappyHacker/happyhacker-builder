#
# OpenWrt Happy Hacker edition makefile
#

.SILENT:

.PHONY: help list all .targets up suspend destroy menuconfig clean dirclean

TARGETS := $(shell script/list_targets.sh)

# The first target is the default target.
# We don't want to build everything by default, we want to show the help instead.
help:
	script/make_help.sh

list:
	script/make_list.sh

.targets: ${TARGETS}

all:
	+make .targets
	make -j1 suspend

up:
	script/make_up.sh

suspend:
	script/make_suspend.sh

destroy:
	script/make_destroy.sh

bin/%: up
	script/make_target.sh \"$(notdir $@)\"

menuconfig: up
	script/make_menuconfig.sh \"$(CONFIG)\"

clean:
	rm -fr ./bin/*
	git checkout -- bin/

dirclean: clean destroy

