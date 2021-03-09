#!/usr/bin/env bash

### get_process_num.sh

case `uname` in
    Linux)  /bin/cat /proc/cpuinfo | grep processor | wc -l;;
    Darwin) sysctl -n hw.ncpu;;
    *) echo 8;;
esac
