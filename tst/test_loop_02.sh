#!/bin/sh

echo "=== INPUT (ftw file) ==="
cat ./tst/res_loop_02.ftw
./tst/res_loop_02.ftw &
sleep 0.1
rm tst/patA.tmp
rm tst/patB.tmp
