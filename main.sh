#!/bin/bash
# socat tcp-listen:2375,fork,reuseaddr unix-connect:/var/run/docker.sock &
# sleep 2
$@