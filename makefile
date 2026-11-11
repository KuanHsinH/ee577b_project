###########################################################################
# EE577B Project Phase 3 - Cardinal NIC and chip multiprocessor           #
# Makefile for Cadence NC-Sim (ncvlog / ncelab / ncsim)                    #
#                                                                         #
# Load the course environment first (C shell):                            #
#   % source setup_v1721.csh                                              #
# From bash:                                                              #
#   $ csh -f -c 'source setup_v1721.csh; make sim'                        #
#                                                                         #
#   make / make sim  compile, elaborate and run the CMP testbench on      #
#                    cmp_test.imem.N.fill + cmp_test.dmem.N.fill;         #
#                    writes dumps/cmp_test.dmem.N.dump (N = 0..15)        #
#   make test        make sim; the testbench also compares the sixteen    #
#                    data memories with expected_dmem.N.dump              #
#   make nic         compile and run the NIC testbench (tb_cardinal_nic)  #
#   make node        compile and run the one-router+NIC tile testbench    #
#   make simg        CMP simulation in the SimVision GUI                   #
#   make nicg        NIC testbench in the SimVision GUI                    #
#   make nodeg       one-router+NIC testbench in the SimVision GUI         #
#   make cmpwave     batch CMP run, records waves/cmp.shm                  #
#   make nicwave     batch NIC run, records waves/nic.shm                  #
#                    (open with: simvision waves/nic.shm)                  #
#   make clean       remove generated files (run before zipping); dumps/  #
#                    is kept, because the dumps are submitted              #
#                                                                         #
# Other programs: make test PREFIX=tests/my_test EXPECTED=tests/my_exp    #
#   reads tests/my_test.imem.N.fill, tests/my_test.dmem.N.fill and        #
#   compares with tests/my_exp.N.dump                                     #
# UNORDERED=5:7 compares MEM[5]-MEM[7] as a set (received packets).      #
#                                                                         #
# Directory structure                                                     #
#   ./         simulation runs here; cmp_test.* files                     #
#   ./dumps    data memory dumps written by the CMP testbench             #
#   ./waves    waveform databases of make cmpwave / make nicwave          #
#   ./design   your synthesizable RTL (*.v, subdirectories allowed):      #
#              cardinal_cmp, cardinal_cpu, cardinal_nic, cardinal_node,   #
#              and your Project 1 mesh (gold_mesh_4x4 + submodules)       #
#   ./tb       tb_cmp.v, tb_cardinal_nic.v, tb_cardinal_node.v            #
#   ./include  instruction/data memory models (do not modify)             #
#   ./scripts  NC-Sim run scripts                                         #
#   ./work     Cadence work library                                       #
###########################################################################
SHELL := /bin/bash

TOP          = tb_cmp
TOP_NIC      = tb_cardinal_nic
TOP_NODE     = tb_cardinal_node
DESIGN_FILES = $(sort $(shell find ./design -name '*.v'))
TB_CMP       = ./tb/tb_cmp.v
TB_NIC       = ./tb/tb_cardinal_nic.v
TB_NODE      = ./tb/tb_cardinal_node.v
INCLUDE_DIRECTORY = ./include

# DesignWare simulation models. SYNOPSYS_DC is set by setup_v1721.csh
# (/tools/synopsys/syn/Y-2026.03 on the vlab servers). List every
# DesignWare component that your design instantiates in DW_COMPONENTS
# (for example DW_COMPONENTS += DW_div_pipe); keep the default entries.
SYNOPSYS_DC   ?= /tools/synopsys/syn/Y-2026.03
DW_SIM_DIR     = $(SYNOPSYS_DC)/dw/sim_ver
DW_COMPONENTS  = DW_div DW_sqrt DW02_mult DW01_addsub DW_shifter
DW_SIM_FILES   = $(foreach c,$(DW_COMPONENTS),$(DW_SIM_DIR)/$(c).v)

SIM_SCRIPT_FILE_GUI    = ./scripts/runscript.tcl
SIM_SCRIPT_FILE_NO_GUI = ./scripts/runscript_nogui.tcl
SIM_SCRIPT_FILE_WAVE   = ./scripts/runscript_wave.tcl

# Program prefix, expected-dump prefix and the unordered range
PREFIX    ?= cmp_test
EXPECTED  ?= expected_dmem
UNORDERED ?= 5:7
DUMP_DIR  ?= dumps
WAVE_DIR  ?= waves
SIM_ARGS   = +PREFIX=$(PREFIX) +DUMP=$(DUMP_DIR)/$(notdir $(PREFIX))
TEST_ARGS  = $(SIM_ARGS) +EXPECTED=$(EXPECTED) $(if $(UNORDERED),+UNORDERED=$(UNORDERED))

NCVLOG_SWITCHES = \
	-STATUS \
	-MESSAGES \
	-UPDATE \
	-INCDIR $(INCLUDE_DIRECTORY) \
	-INCDIR $(DW_SIM_DIR)

# A wrong module or port name stops elaboration (*E,CUVMUR / *E,CUVPOM).
# Port width mismatches are errors too.
NCELAB_SWITCHES = \
	-ACCESS +rwc \
	-NCFATAL INVSUP \
	-NCFATAL CUNOTB \
	-NCFATAL CUVMPW \
	-ERRORMAX 5 \
	-UPDATE \
	-MESSAGES \
	-TIMESCALE '1ns/10ps'

NCSIM_SWITCHES_NO_GUI = \
	-STATUS \
	-NOCOPYRIGHT \
	-MESSAGES \
	-NCFATAL INVSUP \
	-NOWARN DLBRLK \
	-TCL \
	-NOLOG \
	-NOKEY \
	-INPUT $(SIM_SCRIPT_FILE_NO_GUI)

NCSIM_SWITCHES_GUI = \
	-STATUS \
	-NOCOPYRIGHT \
	-MESSAGES \
	-NCFATAL INVSUP \
	-NOWARN DLBRLK \
	-TCL \
	-NOLOG \
	-NOKEY \
	-INPUT $(SIM_SCRIPT_FILE_GUI) \
	-GUI

export TOP

NCSIM_SWITCHES_WAVE = $(subst $(SIM_SCRIPT_FILE_NO_GUI),$(SIM_SCRIPT_FILE_WAVE),$(NCSIM_SWITCHES_NO_GUI))

.PHONY: all sim test nic node simg nicg nodeg cmpwave nicwave clean
all: sim

ana~: $(DESIGN_FILES) $(TB_CMP) $(TB_NIC) $(TB_NODE)
	@mkdir -p work
	@for f in $(DW_SIM_FILES); do \
		test -r "$$f" || { echo "Missing DesignWare simulation model: $$f" >&2; exit 1; }; \
		ncvlog $(NCVLOG_SWITCHES) -work work "$$f" || exit 1; \
	done
	ncvlog $(NCVLOG_SWITCHES) -work work $(DESIGN_FILES)
	ncvlog $(NCVLOG_SWITCHES) -work work $(TB_CMP) $(TB_NIC) $(TB_NODE)
	@touch ana~

elab~: ana~
	ncelab $(NCELAB_SWITCHES) work.$(TOP)
	@touch elab~

elab_nic~: ana~
	ncelab $(NCELAB_SWITCHES) work.$(TOP_NIC)
	@touch elab_nic~

elab_node~: ana~
	ncelab $(NCELAB_SWITCHES) work.$(TOP_NODE)
	@touch elab_node~

sim: elab~
	@mkdir -p $(DUMP_DIR)
	ncsim $(NCSIM_SWITCHES_NO_GUI) work.$(TOP) $(SIM_ARGS)

test: elab~
	@mkdir -p $(DUMP_DIR)
	ncsim $(NCSIM_SWITCHES_NO_GUI) work.$(TOP) $(TEST_ARGS)

nic: elab_nic~
	ncsim $(NCSIM_SWITCHES_NO_GUI) work.$(TOP_NIC)

node: elab_node~
	ncsim $(NCSIM_SWITCHES_NO_GUI) work.$(TOP_NODE)

simg: elab~
	@mkdir -p $(DUMP_DIR)
	TOP=$(TOP) ncsim $(NCSIM_SWITCHES_GUI) work.$(TOP) $(SIM_ARGS)

nicg: elab_nic~
	TOP=$(TOP_NIC) ncsim $(NCSIM_SWITCHES_GUI) work.$(TOP_NIC)

nodeg: elab_node~
	TOP=$(TOP_NODE) ncsim $(NCSIM_SWITCHES_GUI) work.$(TOP_NODE)

cmpwave: elab~
	@mkdir -p $(DUMP_DIR) $(WAVE_DIR)
	@rm -rf $(WAVE_DIR)/cmp.shm
	TOP=$(TOP) WAVE_DB=$(WAVE_DIR)/cmp.shm ncsim $(NCSIM_SWITCHES_WAVE) work.$(TOP) $(TEST_ARGS)

nicwave: elab_nic~
	@mkdir -p $(WAVE_DIR)
	@rm -rf $(WAVE_DIR)/nic.shm
	TOP=$(TOP_NIC) WAVE_DB=$(WAVE_DIR)/nic.shm ncsim $(NCSIM_SWITCHES_WAVE) work.$(TOP_NIC)

clean:
	@rm -f ana~ elab~ elab_nic~ elab_node~ ncvlog.log ncelab.log ncsim.log ncsim.key irun.log xrun.log \
		*.diag *.history
	@rm -rf work INCA_libs xcelium.d ncsim.shm waves.shm xcelium.shm .simvision $(WAVE_DIR)
	@mkdir -p work
