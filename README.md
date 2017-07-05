This is the build system for OpenWrt Happy Hacker firmware images.

---

### WARNING: THIS IS WORK IN PROGRESS. <br><br> IT DOES NOT PROVIDE A FULL WORKING SYSTEM YET. IT MAY BREAK YOUR DEVICE, YOUR COMPUTER, YOUR CAR, SET FIRE TO YOUR HOME, KILL YOUR PETS IN SAVAGE PAGAN RITUALS, JOIN THE MAFIA, DOWNLOAD A CAR, OR WHO KNOWS WHAT ELSE. <br><br> USE AT YOUR OWN PERIL.

---

You'll need a Linux machine (any distro is fine), an active Internet connection. Everything is built inside a sandbox, to better take care of dependencies and
remove OS quirks. We support using either Vagrant and VirtualBox, or Docker containers. We use Vagrant for building locally in our laptops and Docker for our
build server, but it's up to you. By default it is configured to use Docker.

If you choose to use Vagrant and Virtualbox, we recommend installing both from their respective web pages, since distro maintainers for some distros tend to
either keep really old, buggy versions (*ahem* Debian *ahem*) or be misconfigured (*ahem* Fedora *ahem*).

For example, your setup on Debian will be something like this:

```
sudo apt-get update
sudo apt-get install -y git make docker
git clone https://github.com/OpenWrt-HappyHacker/vagrant-happyhacker.git
cd vagrant-happyhacker
vi script/config.sh    # don't be lazy, read all settings ;)
make all
```

If all went well you'll have the binaries in the "bin" directory.

For more options on what else you can do with the build system, type the following command:

```
make help
```

The build VM is configured to use 4 Gb of RAM and 1 CPU core. This is rather conservative, so you may want to change the number of CPUs and RAM as you see fit.
Be careful though, reducing the amount of RAM below 4 Gb may cause the build to fail. You can also edit the configuration script (script/config.sh) to tinker
with the number of Make jobs and parallel building if you want to speed up the builds - our defaults were set as conservative as possible.

Note that the build system requires an active Internet connection, not only during provisioning of the VM but during the compilation process itself. Also, the
build system was only tested against GNU Make, we do not know how well it would work on other versions of Make, if at all.

Regarding multibuilds: currently we have very, very limited support for this. When using Vagrant you can get away with building two different profiles in
parallel, bot not the same profile. With Docker it will not work at all. We may add support for this in the future but for now, just one build at a time.

Happy hacking!

