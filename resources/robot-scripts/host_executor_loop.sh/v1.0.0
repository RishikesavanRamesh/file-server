#!/bin/bash

pipe=/dev/HOST-EXECUTOR-PIPE

# Create the named pipe if it does not exist
if [[ ! -p $pipe ]]; then
  mkfifo $pipe
fi

while true; do
  if read line < $pipe; then
    case $line in
      graceful_shutdown)
        whoami;/usr/local/bin/graceful_shutdown.sh
        ;;
    esac
  fi
done