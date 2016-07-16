# vagrantfiles
This git repo will hosts the Vagrant + Ansible information I use to
bring up a 1 kubernetes master by X kubernetes node configuration. It
is not a shining example of how ansible should be used, but it is a
fairly straightforward example of kubernetes configuration, and
contains a few simple examples, including:

* TLS-encrypted communication between kubernetes components

* An integrated skyDNS/kube2sky replication controller

* A busybox pod

* A simple nginx-based webserver and service available on port 8000 of
  all nodes as well as the master

## Requirements

* Atomic Host vagrant "boxes" - This example uses a home-grown vagrant
  box based on Red Hat Enterprise Linux Atomic Host.  I've taken the downloadable
  (with subscription) qcow2 images and run them through a process
  that "vagrantizes" them :)

* vagrant (I'm using vagrant-libvirt on F23)

* vagrant-reload plugin (for atomic host upgrade + provisioning)

* vagrant-registration plugin

* ansible

## Configuration

Not much to say here.  Edit the Vagrant file and change the names of
the hosts, or add a few more nodes (they are the ones with :primary =>
false), and run "vagrant up --no-parallel"  Running in serial ensures
the master services are up and running prior to the nodes attempting
to connect.

## Caveats

Plenty.  This is not intended to be perfectly stable, production
ready, or perfectly configured.  Use it at your own risk.  As I learn
more, I'll make it better!
