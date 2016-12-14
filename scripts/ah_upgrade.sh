#!/bin/bash
if [ ! -z "$1" ]; then
  ostree refs --delete rhel-atomic-host:rhel-atomic-host/7/x86_64/standard && ostree admin cleanup && atomic host deploy $1
else
  atomic host upgrade
fi
