#!/usr/bin/env python

# Generate the correct OpenWrt image builder command line for our builds.
# Sadly, the image builder completely ignores our build settings, so we
# need to fix this in the command line, so it doesn't try to build a
# standard OpenWrt image instead.

import os
import sys

# Load the configuration file.
with open(".config", "rU") as fd:
    config = [x.strip() for x in fd.readlines()]

# Remove all lines not matching the target configuration, and those not selected.
# Get only the setting name, not the "=y" part from the end.
targets = [x[:-2] for x in config if x.startswith("CONFIG_TARGET_") and x.endswith("=y")]

# Now we need some magic. We don't know beforehand which one of the remaining lines
# indicates the target profile. BUT, we know it follows a pattern. We should see
# something like this:
#
# CONFIG_TARGET_ar71xx=y
# CONFIG_TARGET_ar71xx_generic=y
# CONFIG_TARGET_ar71xx_generic_ZSUNSDREADER=y
#
# Other unrelated lines will look like this:
#
# ...
# CONFIG_TARGET_ROOTFS_SQUASHFS=y
# CONFIG_TARGET_UBIFS_FREE_SPACE_FIXUP=y
# CONFIG_TARGET_IMAGES_GZIP=y
# CONFIG_TARGET_ROOTFS_INCLUDE_KERNEL=y
# CONFIG_TARGET_ROOTFS_INCLUDE_UIMAGE=y
# ...
#
# So we need to find three lines with that progression. Hopefully that won't happen
# by accident with some other unrelated configuration setting... if it does then we
# are pretty much screwed, but at least we can detect it and catch the error here.
#
# I know this is dirty, but as much as it pains me there is no clean way to do it. :(

# Begin with settings that match this pattern: CONFIG_TARGET_*_*_*
candidates = [x for x in targets if x.count("_") == 4]

# For each one, see if we can match the previous components.
# So, for CONFIG_TARGET_1_2_3 we test for CONFIG_TARGET_1_2 and CONFIG_TARGET_1.
found = []
for maybe in candidates:
    original = maybe
    maybe = maybe[:maybe.rfind("_")]
    if maybe in targets:
        maybe = maybe[:maybe.rfind("_")]
        if maybe in targets:
            found.append(original)

# We should have found only one candidate matching this logic.
# If not, fail loudly so we know something went wrong.
# (It is very tempting to use some heuristics here, like a list of valid archs,
# or testing for lowercase characters, but I would rather not risk a false positive).
if len(found) == 0:
    print >>sys.stderr, "Error! Build profile not found!"
    exit(1)
if len(found) > 1:
    print >>sys.stderr, "Error! Conflicting settings found:"
    for x in sorted(found):
        print >>sys.stderr, "    " + x
    exit(1)

# Strip out the rest of the string leaving only the last component.
# That will be the profile string expected by the OpenWrt makefile.
profile = found[0][found[0].rfind("_")+1:]

# The enabled packages should match the ones we have precompiled.
# Or at the very least we should be able to find all of them.
compiled = set()
for root, dirs, files in os.walk("packages"):
    for filename in files:
        if filename.endswith(".ipk"):
            compiled.add(filename[:filename.find("_")])

# Now let's parse the output of the "make info" command.
# To avoid messing with Python's subprocess module,
# we dumped this earlier to a text file in build.sh.
with open("make_info.txt", "rU") as fd:
    make_info = [x.strip() for x in fd.readlines()]

# Get the default packages that OpenWrt has hardcoded in the image builder.
# We may not want some of those packages and could cause builds to fail.
default_packages = set()
for line in make_info:
    if line.startswith("Default Packages: "):
        default_packages.update(line[19:].split(" "))
if not default_packages:
    print >>sys.stderr, "Broken make info output! No default packages found"

# Get the packages for this profile. Some of them may be wrong.
profile_packages = set()
for index in xrange(len(make_info) - 2):
    if make_info[index] == (profile + ":") and make_info[index + 2].startswith("Packages: "):
        profile_packages.update(make_info[index + 2][10:].split(" "))
if not profile_packages:
    print >>sys.stderr, "Broken make info output! No packages found for profile: %s" % profile

# Prepare the list of packages to select and deselect.
selected = default_packages.union(profile_packages)
to_select = compiled.difference(selected)
to_deselect = selected.difference(compiled)

# Return all of the command line options.
packages = " ".join(sorted(to_select)) + " " + " ".join("-"+x for x in sorted(to_deselect))
print 'make image PROFILE=%s PACKAGES="%s" FILES=files/' % (profile, packages)

