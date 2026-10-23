######################################################################
#
# EE-577b 2020 FALL
# : DesignCompiler synthesis script
#   modified by Linyi Hong
#
# use this script as a template for synthesizing combinational logic
#
######################################################################
set_host_options -max_cores 64
# Setting variable for design_name. (top module name)
set design_name $env(DESIGN_NAME);
## For NCSU FreePDK45. setup_v1721.csh supplies OSU45_LIB_DIR; keep a
## machine-wide fallback so the script also gives deterministic diagnostics.
if {[info exists env(OSU45_LIB_DIR)]} {
    set osu45_lib_dir $env(OSU45_LIB_DIR)
} else {
    set osu45_lib_dir /tools/PDK/NCSU45PDK/FreePDK45/osu_soc/lib/files
}

if {![file readable [file join $osu45_lib_dir gscl45nm.db]]} {
    error "Cannot read gscl45nm.db from $osu45_lib_dir. Source setup_v1721.csh first."
}

set search_path [list . $osu45_lib_dir $env(SYNOPSYS_DC)/libraries/syn]
set target_library { gscl45nm.db }
set synthetic_library [list dw_foundation.sldb standard.sldb ]
set link_library [list * gscl45nm.db dw_foundation.sldb standard.sldb]


# Reading source verilog file.
# copy your verilog file into ./src/ before synthesis.
file mkdir report netlist .dc_work
define_design_lib WORK -path ./.dc_work
analyze -format verilog ./src/${design_name}.v ;
elaborate $design_name ;

# Setting $design_name as current working design.
# Use this command before setting any constraints.
current_design $design_name ;

# If you have multiple instances of the same module,
# use this so that DesignCompiler optimizes each instance separately.
uniquify ;

# Linking your design into the cells in standard cell libraries.
# This command checks whether your design can be compiled
link ;

# Create a clock.
set CK_PER  1.45
# -period [val in ns] -waveform [list 0 (50% of clk per in ns)] 
create_clock -name clk -period ${CK_PER} -waveform [list 0 [expr ${CK_PER}/2]] [get_ports clk]
#create_clock -name CLK -period 5.0 -waveform [list 0 2.5] [get_ports CLK]
# Setting timing constraints for combinational logic.
# Specifying maximum delay from inputs to outputs
# set_max_delay [clk per] ...
set_max_delay ${CK_PER} -to [all_outputs];
set_max_delay ${CK_PER} -from [all_inputs]
;
# "check_design" checks the internal representation of the
# current design for consistency and issues error and
# warning messages as appropriate.
check_design > report/$design_name.check_design ;

# Perforing synthesis and optimization on the current_design.
compile ;

# For better synthesis result, use "compile_ultra" command.
# compile_ultra is doing automatic ungrouping during optimization,
# therefore sometimes it's hard to figure out the critical path 
# from the synthesized netlist.
# So, use "compile" command for now.

# Writing the synthesis result into Synopsys db format.
# You can read the saved db file into DesignCompiler later using
# "read_db" command for further analysis (timing, area...).
#write -xg_force_db -format db -hierarchy -out db/$design_name.db ;

# Generating timing and are report of the synthezied design.
report_timing > report/$design_name.timing ;
report_area > report/$design_name.area ;
report_power > report/$design_name.power ;

# Writing synthesized gate-level verilog netlist.
# This verilog netlist will be used for post-synthesis gate-level simulation.
change_names -rules verilog -hierarchy ;
write -format verilog -hierarchy -out netlist/${design_name}_syn.v ;

# Writing Standard Delay Format (SDF) back-annotation file.
# This delay information can be used for post-synthesis simulation.
write_sdf netlist/${design_name}_syn.sdf;
write_sdc netlist/${design_name}_syn.sdc
