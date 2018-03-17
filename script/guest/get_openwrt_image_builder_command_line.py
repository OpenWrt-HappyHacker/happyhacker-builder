#!/usr/bin/env python

# Generate the correct OpenWrt image builder command line for our builds.
# Sadly, the image builder completely ignores our build settings, so we
# need to fix this in the command line, so it doesn't try to build a
# standard OpenWrt image instead.

import os
import sys

# Load the target and profiles info file.
with open(".targetinfo", "rU") as fd:
    targetinfo = [x.strip() for x in fd.readlines()]
targetinfo = [x for x in targetinfo if x]

# Get the list of all possible profile names.
profiles = [x[16:] for x in targetinfo if x.startswith("Target-Profile:")]

# Get the list of all possible target names.
##targets = [x[8:] for x in targetinfo if x.startswith("Target:")]

# Load the configuration file.
with open(".config", "rU") as fd:
    config = [x.strip() for x in fd.readlines()]
config = [x for x in config if x]

# We should see something like this:
#
# CONFIG_TARGET_ar71xx=y
# CONFIG_TARGET_ar71xx_generic=y
# CONFIG_TARGET_ar71xx_generic_ZSUNSDREADER=y
#
# We need the last one to identify the build profile.

# Get all the selected configuration options for the target.
# One of them will be the one that selects the target and profile.
# Get only the setting name, not the "=y" part from the end.
config_target = [x[:-2] for x in config if x.startswith("CONFIG_TARGET_") and x.endswith("=y")]
config_target = [x for x in config_target if not x.isupper()]
config_target = sorted(config_target)
config_target = config_target[::-1]

# The last token of one of those should be the profile.
##target  = None
profile = None
for x in config_target:
    y = x.split("_")
    z = y[-1]
    if z in profiles:
        ##print >>sys.stderr, x
        profile = z
        ##target  = "_".join(y[2:-1])
        break
if profile is None:
    print >>sys.stderr, "Error! Build profile not found!"
    exit(1)

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
    print >>sys.stderr, "Warning: No default packages found"

# Get the non-default packages that OpenWrt has hardcoded in the image builder.
# We may not want some of those packages and could cause builds to fail.
profile_packages = set()
for index in xrange(len(make_info) - 2):
    if make_info[index] == (profile + ":") and make_info[index + 2].startswith("Packages: "):
        profile_packages.update(make_info[index + 2][10:].split(" "))
if not profile_packages and profile != "Default":
    print >>sys.stderr, "Warning: No packages found for profile: %s" % profile

# Prepare the list of packages to select and deselect.
selected = default_packages.union(profile_packages)
to_select = compiled.difference(selected)
to_deselect = selected.difference(compiled)

# Return all of the command line options.
packages = " ".join(sorted(to_select)) + " " + " ".join("-"+x for x in sorted(to_deselect))
print 'make image PROFILE=%s PACKAGES="%s" FILES=files/' % (profile, packages)

