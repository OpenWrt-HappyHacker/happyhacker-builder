This is a Vagrant setup to build OpenWRT Happy Hacker firmware images.

You'll need a Linux machine (any distro is fine), an active Internet connection, and also you'll have to install Vagrant and Virtualbox. We recommend installing both from their
respective web pages, since distro maintainers for some distros tend to either keep really old, buggy versions (*ahem* Debian *ahem*) or be misconfigured (*ahem* Fedora *ahem*).

For example, your setup on Debian will be something like this:

```
sudo apt-get update
sudo apt-get install make vagrant virtualbox
make all
```

If all went well you'll have the binaries in the "bin" directory.

For more options on what else you can do with the build system, type the following command:

```
make help
```

The build VM is configured to use 10 Gb of RAM and 4 CPU cores. You can change the number of CPUs as you see fit, but reducing the amount of RAM below 4 Gb may cause the build to 
fail. You can also edit the configuration script (script/config.sh) to tinker with the number of Make jobs and parallel building if you want to speed up the builds - our defaults
were set as conservative as possible.

Note that the build system requires an active Internet connection, not only during provisioning of the VM but during the compilation process itself. Also, the build system was
only tested against GNU Make, we do not know how well it would work on other versions of Make, if at all.
