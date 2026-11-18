# Design Compiler synthesis for either Phase 2 Cardinal CPU.
# The Makefile supplies DESIGN_NAME, DESIGN_DIR, OUTPUT_DIR, and CLOCK_PERIOD_NS.

foreach name {DESIGN_NAME DESIGN_DIR OUTPUT_DIR CLOCK_PERIOD_NS SYNOPSYS_DC OSU45_LIB_DIR} {
    if {![info exists env($name)] || $env($name) eq ""} {
        error "Missing $name; run through Makefile.cpu_synth after loading the course setup"
    }
}

set design_name $env(DESIGN_NAME)
if {$design_name ne "cardinal_cpu" && $design_name ne "cardinal_cpu_bp_v1"} {
    error "Unsupported top module: $design_name"
}
set design_dir [file normalize $env(DESIGN_DIR)]
set output_dir [file normalize $env(OUTPUT_DIR)]
set clock_period_ns [expr {double($env(CLOCK_PERIOD_NS))}]
if {$clock_period_ns <= 0} {
    error "CLOCK_PERIOD_NS must be positive"
}

set osu45_lib_dir [file normalize $env(OSU45_LIB_DIR)]
if {![file readable [file join $osu45_lib_dir gscl45nm.db]]} {
    error "Cannot read gscl45nm.db from $osu45_lib_dir"
}

set sources [list \
    [file join $design_dir ALU.v] \
    [file join $design_dir decoder.v] \
    [file join $design_dir register_file.v] \
]
if {$design_name eq "cardinal_cpu_bp_v1"} {
    lappend sources [file join $design_dir BPB.v]
}
lappend sources [file join $design_dir ${design_name}.v]
foreach source $sources {
    if {![file readable $source]} {
        error "Cannot read RTL source: $source"
    }
}

file mkdir $output_dir
file mkdir [file join $output_dir report]
file mkdir [file join $output_dir netlist]
file mkdir [file join $output_dir dc_work]

set search_path [list . $design_dir $osu45_lib_dir \
    [file join $env(SYNOPSYS_DC) libraries syn]]
set target_library {gscl45nm.db}
set synthetic_library {dw_foundation.sldb standard.sldb}
set link_library [list * gscl45nm.db dw_foundation.sldb standard.sldb]

define_design_lib WORK -path [file join $output_dir dc_work]
analyze -format verilog $sources
elaborate $design_name
current_design $design_name
uniquify
link

# Use the same constraints for both CPUs. The 5 ns default comes from the
# supplied course synthesis example; override CLOCK_PERIOD_NS in make.
create_clock -name clk -period $clock_period_ns \
    -waveform [list 0 [expr {$clock_period_ns / 2.0}]] [get_ports clk]
set_max_delay $clock_period_ns -to [all_outputs]
set_max_delay $clock_period_ns -from [all_inputs]

check_design > [file join $output_dir report ${design_name}.check_design]
compile

report_timing > [file join $output_dir report ${design_name}.timing]
report_area > [file join $output_dir report ${design_name}.area]
report_cell > [file join $output_dir report ${design_name}.cell]
report_power > [file join $output_dir report ${design_name}.power]

change_names -rules verilog -hierarchy
write -format verilog -hierarchy \
    -out [file join $output_dir netlist ${design_name}_syn.v]
write_sdf [file join $output_dir netlist ${design_name}_syn.sdf]
write_sdc [file join $output_dir netlist ${design_name}_syn.sdc]

puts "Synthesis complete: $design_name -> $output_dir"
exit 0
