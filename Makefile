#
# OpenWrt Happy Hacker edition makefile
#

.SILENT:

.PHONY: help list all .targets up suspend destroy menuconfig clean dirclean

TARGETS := $(shell script/host/list_profiles.sh)

# The first target is the default target.
# We don't want to build everything by default, we want to show the help instead.
help:
	script/host/make_help.sh

list:
	script/host/make_list.sh

.targets: ${TARGETS}

all:
	+make .targets
	make -j1 suspend

up:
	script/host/make_up.sh

suspend:
	script/host/make_suspend.sh

destroy:
	script/host/make_destroy.sh

provision: up
	script/host/make_provision.sh

ssh: up
	script/host/make_ssh.sh

bin/%: up
	script/host/make_target.sh $(notdir $@)

menuconfig: up
	script/host/make_menuconfig.sh $(CONFIG)

clean:
	script/host/make_clean.sh

dirclean: clean destroy
