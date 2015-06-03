# vagrantfiles
This git repo will host all the various vagrant configurations I use.

## Requirements

* Atomic Host vagrant "boxes" - Most of these use a home-grown vagrant "box" based on Red Hat Atomic Host.  I've taken the downloadable (with subscription) qcow2 images and run them through a process that "vagrantizes" them :)

* vagrant (I'm using vagrant-libvirt on F22)

* vagrant-reload plugin (for atomic host upgrade + provisioning)

* vagrant-registration plugin
