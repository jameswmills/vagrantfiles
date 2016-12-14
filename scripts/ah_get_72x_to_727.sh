#!/bin/bash
current=$(atomic host status|grep ^\*|awk '{print $4}'|awk -F. '{print $1$2$3}')

if [ ${current} -lt 727 ]; then
  echo "Moving to 7.2.7 before continuing"
  ostree refs --delete rhel-atomic-host:rhel-atomic-host/7/x86_64/standard && ostree admin cleanup && atomic host deploy 7.2.7
fi
