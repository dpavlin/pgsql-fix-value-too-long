#!/bin/sh -xe

touch errors
(
psql -l | grep ibatisti | awk '{ print $1 }' | xargs -i dropdb {}
./pgsql-fix-value-too-long.pl errors $1 | \
( psql --echo-queries template1 2>&1 )
2>&1 ) | tee log
grep -A 1 'value too long' log | tee -a errors
