#!/bin/tcsh

set DOFILE = "$1"
set LOGFILE = "$2"

/tools/cadence/CONFRML252/bin/lec -L \
    -NOGui -NOLicwait \
    -Dofile "$DOFILE" \
    -LOGfile "$LOGFILE"
