
# NC-Sim Command File
# TOOL:	ncsim(64)	15.20-s086
#

set tcl_prompt1 {puts -nonewline "ncsim> "}
set tcl_prompt2 {puts -nonewline "> "}
set vlog_format %h
set vhdl_format %v
set real_precision 6
set display_unit auto
set time_unit module
set heap_garbage_size -200
set heap_garbage_time 0
set assert_report_level note
set assert_stop_level error
set autoscope yes
set assert_1164_warnings yes
set pack_assert_off {}
set severity_pack_assert_off {note warning}
set assert_output_stop_level failed
set tcl_debug_level 0
set relax_path_name 1
set vhdl_vcdmap XX01ZX01X
set intovf_severity_level ERROR
set probe_screen_format 0
set rangecnst_severity_level ERROR
set textio_severity_level ERROR
set vital_timing_checks_on 1
set vlog_code_show_force 0
set assert_count_attempts 1
set tcl_all64 false
set tcl_runerror_exit false
set assert_report_incompletes 0
set show_force 1
set force_reset_by_reinvoke 0
set tcl_relaxed_literal 0
set probe_exclude_patterns {}
set probe_packed_limit 4k
set probe_unpacked_limit 16k
set assert_internal_msg no
set svseed 1
set assert_reporting_mode 0
alias iprof profile
database -open -shm -into waves.shm waves -default
probe -create -database waves tb_cardinal_nic.clk tb_cardinal_nic.reset tb_cardinal_nic.addr tb_cardinal_nic.nicEn tb_cardinal_nic.nicEnWr tb_cardinal_nic.d_in tb_cardinal_nic.d_out tb_cardinal_nic.net_si tb_cardinal_nic.net_ri tb_cardinal_nic.net_di tb_cardinal_nic.net_so tb_cardinal_nic.net_ro tb_cardinal_nic.net_do tb_cardinal_nic.net_polarity tb_cardinal_nic.dut.in_full tb_cardinal_nic.dut.out_full tb_cardinal_nic.dut.in_buf tb_cardinal_nic.dut.out_buf

simvision -input /home/klin7311@vlab.usc.edu/ee577b/NoC_mesh_project/phase0_NoC_router/ee577b_project/.simvision/862260_klin7311_viterbi-scf02.vlab.usc.edu_autosave.tcl.svcf
