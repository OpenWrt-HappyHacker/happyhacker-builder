# docker build -t happyhacker/openwrtbuilder:0.1 .
FROM ubuntu:15.04
MAINTAINER "b0rh" <francisco@garnelo.eu>
ENV container docker
ENV LC_ALL C
ENV DEBIAN_FRONTEND noninteractive
ENV TERM xterm-256color

#https://github.com/tozd/docker-ubuntu-systemd

# setup locale and timezone
RUN locale-gen en_US.UTF-8 \
 && update-locale LANG=en_US.UTF-8 \
 \
 && echo "UTC" > /etc/timezone \
 && dpkg-reconfigure tzdata

# tweaks for docker from mkimage.sh
# https://github.com/docker/docker/blob/master/contrib/mkimage/debootstrap
RUN rm -f /etc/apt/apt.conf.d/01autoremove-kernels \
 && echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \
 && echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \
 && echo 'Dir::Cache::pkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
 && echo 'Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
 \
 && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \
 \
 && echo 'Acquire::GzipIndexes "true";' > /etc/apt/apt.conf.d/docker-gzip-indexes \
 && echo 'Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes \
 \
 && echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests

# tweaks for systemd
RUN systemctl mask -- \
    -.mount \
    dev-mqueue.mount \
    dev-hugepages.mount \
    etc-hosts.mount \
    etc-hostname.mount \
    etc-resolv.conf.mount \
    proc-bus.mount \
    proc-irq.mount \
    proc-kcore.mount \
    proc-sys-fs-binfmt_misc.mount \
    proc-sysrq\\\\x2dtrigger.mount \
    sys-fs-fuse-connections.mount \
    sys-kernel-config.mount \
    sys-kernel-debug.mount \
    tmp.mount \
 \
 && systemctl mask -- \
    console-getty.service \
    display-manager.service \
    getty-static.service \
    getty\@tty1.service \
    hwclock-save.service \
    ondemand.service \
    systemd-logind.service \
    systemd-remount-fs.service \
 \
 && ln -sf /lib/systemd/system/multi-user.target /etc/systemd/system/default.target \
 \
 && ln -sf /lib/systemd/system/halt.target /etc/systemd/system/sigpwr.target

# workarounds for common problems
RUN echo "resolvconf resolvconf/linkify-resolvconf boolean false" | debconf-set-selections

# upgrade OS
RUN apt-get update -qq \
 && apt-get upgrade --yes --force-yes

# system packages
RUN apt-get update -qq \
 && apt-get install -y \
    rsyslog \
    systemd \
    apt-utils \
    systemd-cron \
 \
 && sed -i 's/^\($ModLoad imklog\)/#\1/' /etc/rsyslog.conf

# SSH and sudo support
RUN \
  apt-get install -y --no-install-recommends openssh-server sudo

# Builder dependencies
RUN \
  apt-get install -y uuid-runtime


# Vagrant user and ssh key
RUN \
  # "vagrant" User and default ssh certificate
  apt-get install -y curl && \
  useradd -s /bin/bash vagrant && \
  echo vagrant:vagrant | chpasswd -m && \
  install -m 755 -o vagrant -g vagrant -d /home/vagrant && \
  install -m 700 -o vagrant -g vagrant -d /home/vagrant/.ssh && \
  #curl -sL https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub >> /home/vagrant/.ssh/authorized_keys &&\
  echo 'ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key' > /home/vagrant/.ssh/authorized_keys \
  chmod 600 /home/vagrant/.ssh/authorized_keys && \
  chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys && \

  # Root Password: "vagrant"
  echo root:vagrant | chpasswd -m && \

  # Password-less Sudo
  echo 'vagrant ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/vagrant && \
  chmod 0440 /etc/sudoers.d/vagrant && \

  # SSH Tweaks
  echo 'UseDNS no' >> /etc/ssh/sshd_config && \

  # for Vagrant OS detection
  # https://github.com/mitchellh/vagrant/blob/v1.8.4/plugins/guests/ubuntu/guest.rb
  apt-get install -y --no-install-recommends lsb-release && \

  # Other Docker image fixes
  mkdir -p /var/run/sshd && \
  echo "export TERM=xterm-256color" > /home/vagrant/.bashrc && \
  rm /usr/sbin/policy-rc.d 

# Openwrt and happyhacker build dependencies
RUN \
# Install the Haveged daemon. This should somewhat improve the entropy pool.
# We need a good entropy pool to generate the various keys we need.

  apt-get install -y haveged &&\

  # Install all possible dependencies for all OpenWrt packages.
  # This is more than we need right now but it covers all future possibilities,
  # as well as what users may want in their custom ROMs.
  
  apt-get install -y asciidoc bash bc bcc bin86 binutils build-essential bzip2 \
  fastjar flex g++ gawk gcc gcc-multilib genisoimage gettext git-core \
  intltool jikespg libboost-dev libgtk2.0-dev libncurses5-dev libssl-dev \
  libusb-dev libxml-parser-perl make mercurial openjdk-7-jdk patch \
  perl-modules python-dev rsync ruby sdcc sharutils subversion unzip \
  util-linux wget xsltproc zlib1g-dev curl && \

  # The following packages are required by our scripts.
  apt-get install -y colorgcc colormake coreutils makepasswd && \

  # Install Tor and immediately stop the daemon.
  # We will use it only to generate hidden service keys, it will not connect
  # to the rest of the Tor network at any time.
  apt-get install -y tor && \

  # "vagrant-cachier" friendly
  rm /etc/apt/apt.conf.d/docker-clean && \

  # Cleanup
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* && \

  # Create the symlinks to the /INSIDE and /OUTSIDE directories.
  ln -s /home/vagrant /INSIDE && \
  ln -s /vagrant /OUTSIDE

VOLUME [ "/sys/fs/cgroup" ]
CMD ["/sbin/init"]
EXPOSE 22
