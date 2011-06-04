#!/bin/sh

echo "=== INPUT (ftw file) ==="
cat ./tst/res_loop_01.ftw
./tst/res_loop_01.ftw &
sleep 1
rm tst/patA.tmp
rm tst/patB.tmp
