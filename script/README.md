The config.sh script is a Bash/Ruby polyglot - it is used exclusively to load global configuration variables and is read from shell scripts both in the host and guest systems, as well as from the Vagrantfile.

The rest of the files are split up into directories according to the following classification:

  data/         Data files. May be used by both the guest and the host systems.
  guest/        Scripts to be run in the context of the guest system.
  host/         Scripts to be run in the context of the host system.

All of these scripts will be ran automatically by the build system. You do not need to run any of them yourself.
