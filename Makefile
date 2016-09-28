#
# OpenWRT Happy Hacker edition makefile
#

.SILENT:

.PHONY: help list all .targets up suspend destroy menuconfig clean dirclean

TARGETS := $(shell script/list_targets.sh)

# The first target is the default target.
# We don't want to build everything by default, we want to show the help instead.
help:
	script/help.sh

list:
	script/show_targets.sh

.targets: ${TARGETS}

all:
	+make .targets
	make -j1 suspend

up:
	vagrant up

suspend:
	vagrant suspend

destroy:
	vagrant destroy

bin/%: up
	vagrant ssh -c "/vagrant/script/build.sh \"$(notdir $@)\""

menuconfig:
	vagrant ssh -c "/vagrant/script/menuconfig.sh \"$(CONFIG)\""

clean:
	rm -fr ./bin/*
	git checkout -- bin/

dirclean: clean destroy
