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

* The ability to deploy containerized kubernetes master services (default), or RPM-based (CONTAINERIZED=false).

* The ability to upgrade to the latest version of Atomic Host
  (default), or to remain at the version of the vagrant "box" used (AHUPGRADE=false)

* For containerized kubernetes, the proper version will be chosen, "1.2" for 7.2.x deploys, and "latest" for 1.3 deploys

## Requirements

* Atomic Host vagrant "boxes" - This example uses a home-grown vagrant
  box based on Red Hat Enterprise Linux Atomic Host.  I've taken the downloadable
  (with subscription) qcow2 images and run them through a process
  that "vagrantizes" them :) A seperate github repo contains more
  info: https://github.com/jameswmills/vagrantize

* vagrant

* vagrant-libvirt plugin

* vagrant-reload plugin (for atomic host upgrade + provisioning)

* vagrant-registration plugin

* ansible

## Configuration

Edit the Vagrant file and set the value of "ahbase" at the top.  This
Vagrantfile assumes the Atomic Host box will be named
"atomic-$ahbase", so ensure the proper box exists prior to bringing
the environment up.  You can also change the names of the hosts, or
add a few more nodes (they are the ones with :primary => false).

Once you have set the version, run `rh_user=YOUR_RH_USERNAME
rh_pass=YOUR_RH_PASSWORD vagrant up --no-parallel` Running in serial
ensures the master services are up and running prior to the nodes
attempting to connect.

By default, this will deploy a single master/two node setup with
containerized kubernetes master services on Atomic Host upgraded to
the latest production version.  Below are some additional variable you
can pass to tailor the build process.

### Containerized vs RPM-based deploys

If you want RPM-based kubnernetes master services (7.2.x ONLY), pass
`CONTAINERIZED=false` to the above command.  If you want to skip the
upgrade step, pass `AHUPGRADE=false` to the above command.  For example:

```
$ CONTAINERIZED=false rh_user=YOUR_RH_USERNAME rh_pass=YOUR_RH_PASSWORD vagrant up --no-parallel
```

### Skipping the upgrade

If you want to disable the upgrade process, you can pass
`AHUPGRADE=false` to the `vagrant up` command.  This will skip any
upgrade logic.  **NOTE:** This will also skip any `AHVERSION` logic.
More info on that in the next section.

For example:

```
$ AHUPGRADE=false rh_user=YOUR_RH_USERNAME rh_pass=YOUR_RH_PASSWORD vagrant up --no-parallel
```

### Specifying the Atomic Host version to deploy

By default, the process will upgrade each Atomic Host machine to the
latest version.  However, if you need to deploy a specific version,
you can pass `AHVERSION=<version>` to the `vagrant up` command to
deploy a specific version.  There are a few restrictions here:

* The version *must* be newer than the base deployment version

* `AHUPGRADE` must not be set to `false`

* The value of `AHVERSION` must match a version of the deployed OSTREE

For example, assuming our base box version is 7.2.5:

```
$ AHVERSION=7.3 rh_user=YOUR_RH_USERNAME rh_pass=YOUR_RH_PASSWORD vagrant up --no-parallel
```

The above command will perform the following steps:

* deploy the base version of 7.2.5

* Upgrade to 7.2.7 (to avoid a bug with selinux when upgrading from
  earlier than 7.2.7 to 7.3.x)

* Upgrade to 7.3


## Additional examples

In the examples below, I'm going to assume that `rh_user` and `rh_pass` are set in the environmenmt.  You need them, I am just not going to put them here ;)

### From an `atomic-7.2.3` base image, deploy a non-containerized 7.2.3-1 environment

Ensure `ahbase` is set to `7.2.3` and that you have an `atomic-7.2.3` base image, and run:

```
$ AHVERSION=7.2.3-1 CONTAINERIZED=false vagrant up --no-parallel
```

### From an `atomic-7.2.3` base image, deploy a containerized `7.2.5`  environment

Ensure `ahbase` is set to `7.3.2` and that you have an `atomic-7.3.2` base image, and run:

```
$ AHVERSION=7.2.5 vagrant up --no-parallel
```

### From an `atomic-7.2.3` base image, deploy a non-containerized `7.2.3`  environment, skipping any attempt to upgrade

Ensure `ahbase` is set to `7.3.2` and that you have an `atomic-7.3.2` base image, and run:

```
$ AHUPGRADE=false CONTAINERIZED=false vagrant up --no-parallel
```

## Caveats

Plenty.  This is not intended to be perfectly stable, production
ready, or perfectly configured.  Use it at your own risk.  As I learn
more, I'll make it better!  For now, I'll restate some of what I said above:

* If `AHUPGRADE` is set to false, `AHVERSION` will be ignored

* `AHVERSION` cannot be an older release than the base box

* Any upgrade to 7.3.x from < 7.2.7 will include a step to upgrade the box to 7.2.7 before upgrading to 7.3.x

* The base box version is expected to be named "atomic-<version>", where <version> is a released Atomic Host version

* You *cannot* set CONTAINERIZED=false when deploying a 7.3.x environment.  7.3.x removed the kubernetes-master RPMs
