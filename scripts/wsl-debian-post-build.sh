#!/bin/bash

if [[ -n $WSLENV ]]; then
  systemctl --user enable systemd-tmpfiles-setup.service
fi
