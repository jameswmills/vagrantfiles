# vagrantfiles
This git repo will hosts the Vagrant + Ansible information I use to
bring up a 1 kubernetes master by X kubernetes node configuration. It
is not a shining example of how ansible should be used, but it is a
fairly straightforward example of kubernetes configuration, and
contains a few simple examples, including:

* TLS-encrypted communication between kubernetes components

* TLS-encrypted communication between kubernetes and etcd

* An integrated skyDNS/kube2sky replication controller

* An integrated kubernetes-dashboard (port 80 of all nodes)

* A busybox pod

* A simple nginx-based webserver and service available on port 8000 of
  all nodes as well as the master

* The ability to deploy containerized kubernetes master services (default), or RPM-based (CONTAINERIZED=false)

* The ability to upgrade to the latest version of Atomic Host
  (default), or to remain at the version of the vagrant "box" used (AHUPGRADE=false)

## Requirements

* Atomic Host vagrant "boxes" - This example uses a home-grown vagrant
  box based on Red Hat Enterprise Linux Atomic Host.  I've taken the downloadable
  (with subscription) qcow2 images and run them through a process
  that "vagrantizes" them :) A seperate github repo contains more
  info: https://github.com/jameswmills/vagrantize

* vagrant (I'm using vagrant-libvirt on F23)

* vagrant-reload plugin (for atomic host upgrade + provisioning)

* vagrant-registration plugin

* ansible

## Configuration

Not much to say here.  Edit the Vagrant file and change the names of
the hosts, or add a few more nodes (they are the ones with :primary =>
false), and run `rh_user=YOUR_RH_USERNAME rh_pass=YOUR_RH_PASSWORD
vagrant  up --no-parallel`  Running in serial ensures
the master services are up and running prior to the nodes attempting
to connect.

By default, this will deploy a single master/two node setup with
containerized kubernetes master services on Atomic Host upgraded to
the latest production version.  If you want RPM-based kubnernetes
master services, pass `CONTAINERIZED=false` to the above command.  If
you want to skip the upgrade step, pass `AHUPGRADE=false` to the above command.

## Caveats

Plenty.  This is not intended to be perfectly stable, production
ready, or perfectly configured.  Use it at your own risk.  As I learn
more, I'll make it better!
