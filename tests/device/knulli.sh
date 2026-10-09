#!/bin/bash
# Run a command on the Knulli test device: knulli.sh '<cmd>'  (KNULLI_HOST overrides the address)
exec sshpass -f "$HOME/.ssh/knulli.pass" ssh -o StrictHostKeyChecking=accept-new root@${KNULLI_HOST:-knulli} "$@"
