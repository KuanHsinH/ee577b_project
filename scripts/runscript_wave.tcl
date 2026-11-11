# Batch waveform run (make nicwave, make cmpwave): records every signal of
# the testbench hierarchy into the database $WAVE_DB, runs to the end and
# exits. Open the result with: simvision <database>
set tb $env(TOP);
database -open wavedb -shm -into $env(WAVE_DB) -default
probe -create -database wavedb $tb -all -depth all
run
exit
