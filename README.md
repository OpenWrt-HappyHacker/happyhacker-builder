This is the build system for OpenWrt Happy Hacker firmware images.

---

### WARNING: THIS IS WORK IN PROGRESS. <br><br> IT DOES NOT PROVIDE A FULL WORKING SYSTEM YET. IT MAY BREAK YOUR DEVICE, YOUR COMPUTER, YOUR CAR, SET FIRE TO YOUR HOME, KILL YOUR PETS IN SAVAGE PAGAN RITUALS, JOIN THE MAFIA, DOWNLOAD A CAR, OR WHO KNOWS WHAT ELSE. <br><br> USE AT YOUR OWN PERIL.

---

Frquently Asked Questions
=========================

* Ok, what is this?

This is our attempt at building a reasonable secure setup for disposable Tor nodes. These nodes can be used for anything, from simple exit nodes to hosting hidden services, in a very cheap way. We call them "disposable" because you can do precisely that: since they cost so little, you can improve your OPSEC by just using them briefly and then never again. That way, if they are ever compromised or discovered, they cannot be traced back to you.

In order to keep costs down, we picked a very cheap hardware from China, a MicroSD card reader that just so happens to contain a Wi-Fi card inside.

* Is this ready to use? Can I Hack the Planet with this?

Short answer: not yet.

Currently we have a functional build system, but the firmware images still need a little bit of retouching. Also, as it is now you have to recompile everything each time you generate a new image and that's inefficient.

Our plans for the near future are: fix a few things in OpenWrt that don't quite work the way we want it to, cache precompiled code so we only need to compile once to generate multiple firmware images, and upload our own precompiled images for the lazy to just download and flash.

* But I saw your talk and you had demo of a working system! Where is it?

You can find a copy of the firmware we used for the demos in the [Presentations](https://github.com/OpenWrt-HappyHacker/Presentations/tree/master/Demos) repo.

* Can this thing be used by Bad People?

Probably. But as with any other privacy oriented technology, we believe the potential for good, as for example evading censorship in repressive regimes and aiding whistleblowers, outweighs the risks. Also, the baddies don't need any help from us - they are well funded and very motivated to come up with their own systems anyway.

* How can this be used legally in my country?

We are not lawyers. Better ask one instead of us! We only take care of the technical aspects of this research project, and we give no guarantees of any kind.

Be smart, don't be reckless, find out what you can and cannot do before having fun! ;)

And remember, no technical solution will ever replace good OPSEC.

* Where do I get those gadgets?

Here is a handy link to DealExtreme. This is the cheapest one we found, most other sites sell you the Zsun at a much higher price (sometimes double!).

  http://www.dx.com/p/zsun-wi-fi-usb-2-0-card-reader-for-tablet-pc-ipad-iphone-android-mobile-phone-black-379018

* How do I compile a new firmware image?

You'll need a Linux machine (any distro is fine), an active Internet connection. Everything is built inside a sandbox, to better take care of dependencies and remove OS quirks. We support using either Vagrant and VirtualBox, LXD containers or Docker containers. We use Vagrant or LXD for building locally in our laptops and Docker for our build server, but it's up to you. By default it is configured to use Vagrant.

There's also an option to disable sandboxing completely, in which case all the required dependencies are installed in your host machine. Use that option with care! When unsandboxed, the system is always assumed to be Ubuntu 16.04. (That's why we sandbox it, so you don't have to run that horrible, horrible distro). ;)

If you choose to use Vagrant and Virtualbox, we recommend installing both from their respective web pages, since distro maintainers for some distros tend to either keep really old, buggy versions (\*ahem\* Debian \*ahem\*) or be misconfigured (\*ahem\* Fedora \*ahem\*).

For example, your setup on Ubuntu with LXD will be something like this (DO NOT BLINDLY COPY AND PASTE ON YOUR SHELL, READ IT FIRST):

```
sudo apt-get update
sudo apt-get install -y git make lxd
git clone https://github.com/OpenWrt-HappyHacker/happyhacker-builder.git
cd happyhacker-builder
vi script/config.sh    # don't be lazy, read all settings ;)
vi script/data/wifisdb.csv   # same here, pay attention to it
make all
```

On Debian with Vagrant it would look like this (AGAIN, DO NOT COPY AND PASTE, READ IT FIRST):

```
sudo apt-get update
sudo apt-get install -y git make vagrant virtualbox
git clone https://github.com/OpenWrt-HappyHacker/happyhacker-builder.git
cd happyhacker-builder
vi script/config.sh    # don't be lazy, read all settings ;)
vi script/data/wifisdb.csv   # same here, pay attention to it
make all
```

On Debian with Docker it may be something like this (do bear in mind Docker support is currently experimental):

```
sudo apt-get update
sudo apt-get install -y git make docker
git clone https://github.com/OpenWrt-HappyHacker/happyhacker-builder.git
cd happyhacker-builder
vi script/config.sh    # don't be lazy, read all settings ;)
vi script/data/wifisdb.csv   # same here, pay attention to it
make all
```

And if you just prefer to set up your own sandbox (or run Ubuntu 16 in bare metal), try something like this:
```
sudo apt-get update
sudo apt-get install -y git make
git clone https://github.com/OpenWrt-HappyHacker/happyhacker-builder.git
cd happyhacker-builder
vi script/config.sh    # don't be lazy, read all settings ;)
vi script/data/wifisdb.csv   # same here, pay attention to it
make all
```

If all went well you'll have the binaries in the "bin" directory.

For more options on what else you can do with the build system, type the following command:

```
make help
```

The build VM is configured to use 4 Gb of RAM and 1 CPU core. This is rather conservative, so you may want to change the number of CPUs and RAM as you see fit. Be careful though, reducing the amount of RAM below 4 Gb may cause the build to fail. You can also edit the configuration script (script/config.sh) to tinker with the number of Make jobs and parallel building if you want to speed up the builds - our defaults were set as conservative as possible.

Note that the build system requires an active Internet connection, not only during provisioning of the VM but during the compilation process itself. Also, the build system was only tested against GNU Make, we do not know how well it would work on other versions of Make, if at all.

Regarding multibuilds: currently we have very, very limited support for this. When using Vagrant you can get away with building two different profiles in parallel, bot not the same profile. With Docker it will not work at all. We may add support for this in the future but for now, just one build at a time.

* How do I flash a new firmware image?

The bin/ directory contains each and every build of the firmware images. Pick one, you'll need the .bin files.

There is a flashing script in [script/install.sh](script/install.sh). Check out the comments at the beginning for precise instructions on how to use it.

* Ok, I flashed it, what now?

Hopefully, you didn't forget to set the Wi-Fi credentials :D but if you did, there are default ones too. Set up an AP so the device can connect to it, plug it on somewhere and wait a while (could be several minutes for the first boot).

The device will have an SSH daemon over Tor. You'll need the Dropbear client to connect to it.

In the output folder for your build you will find a makefile, with the "make ssh" command you can connect to the device using Tor and Dropbear. Also try typing "make help" to see what else you can do with it.

* I tried compiling but it says compilation failed. What gives?

Most of the times, when compilation fails it's because OpenWrt downloads a lot of crap off the Internet during the build. Some of that stuff is hosted in Sourceforge and other less-than-ideal sites, so downloads frequently fail. We are working on a fix for that, possibly by pre-downloading everything and creating a local cache.

The second most common reason for builds to fail is if you modified the configuration to give the build system less than 4 Gb of RAM, or if you are creating your own custom image (in which case, if you select too many OpenWrt packages you may run out of space in ROM). The second problem will be fixed in the near future, we want to make OpenWrt boot from the MicroSD card directly instead of using ROM.

In the event of any other problems compiling the code, let us know! Open a new issue in Github or email us at: crapula@alligatorcon.pl

Happy Hacking!
