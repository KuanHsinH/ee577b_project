#!/bin/csh
# EDA tools setup for viterbi-scf02.vlab.usc.edu
# Paths are adapted from setup_v1721.csh to the current /tools installation.
 
alias prepend 'if (-d \!:2) if ("$\!:1" \!~ *"\!:2"*) setenv \!:1 "\!:2":${\!:1}'
alias extend  'if (-d \!:2) if ("$\!:1" \!~ *"\!:2"*) setenv \!:1 ${\!:1}:\!:2'
 
# License servers used by the current Viterbi modulefiles.
setenv LM_LICENSE_FILE 1721@lic-cadence.usc.edu:1722@lic-cadence.usc.edu
setenv CDS_LIC_FILE 1721@lic-cadence.usc.edu:1722@lic-cadence.usc.edu
setenv SNPSLMD_LICENSE_FILE 1720@viterbi-lic01.vlab.usc.edu
 
# -------------------------------------------------------------------------
# Cadence tools
# -------------------------------------------------------------------------
setenv SPECTRE_DEFAULTS -E
setenv CDS_AUTO_64BIT ALL
setenv CDS_Netlisting_Mode Analog
 
setenv CDSBASE /tools/cadence
 
# Virtuoso / OpenAccess
setenv CDS_INST_DIR $CDSBASE/IC251
setenv CADENCE_IC $CDSBASE/IC251
setenv OA_HOME $CADENCE_IC/oa_v22.62.009
 
# Incisive is retained for the EE577 makefiles (ncvlog/ncelab/ncsim).
setenv CADENCE_IN $CDSBASE/INCISIVE152
setenv INCISIVE_HOME $CADENCE_IN
setenv INCISIVE_BIN $CADENCE_IN/tools.lnx86/inca/bin
setenv INCISIVE_BIN64 $INCISIVE_BIN/64bit
 
# Current Cadence product equivalents on this server.
setenv CADENCE_IV $CDSBASE/DDI251/INNOVUS251
setenv CADENCE_CF $CDSBASE/CONFRML252
setenv CONFORMAL_HOME $CADENCE_CF
setenv CADENCE_MM $CDSBASE/SPECTRE251
setenv CADENCE_XC $CDSBASE/XCELIUM2509
setenv CADENCE_SP $CDSBASE/SPECTRE251
 
# Legacy product variables retained for scripts that reference their names.
setenv CADENCE_AS $CDSBASE/ASSURA41
 
# Cadence executable paths. prepend ignores directories that are not installed.
prepend PATH $CADENCE_IC/bin
prepend PATH $CADENCE_IC/tools.lnx86/dfII/bin/64bit
prepend PATH $CADENCE_IC/tools.lnx86/dfII/bin
prepend PATH $CADENCE_IN/bin
prepend PATH $INCISIVE_BIN64
prepend PATH $INCISIVE_BIN
prepend PATH $CADENCE_IN/tools.lnx86/simvision/bin/64bit
prepend PATH $CADENCE_IN/tools.lnx86/simvision/bin
prepend PATH $CADENCE_IV/bin
prepend PATH $CADENCE_IV/tools.lnx86/innovus/bin/64bit
prepend PATH $CADENCE_IV/tools.lnx86/innovus/bin
prepend PATH $CADENCE_IV/tools/bin
prepend PATH $CADENCE_MM/bin
prepend PATH $CADENCE_MM/tools.lnx86/spectre/bin/64bit
prepend PATH $CADENCE_MM/tools.lnx86/spectre/bin
prepend PATH $CADENCE_CF/bin
prepend PATH $CADENCE_XC/bin
prepend PATH $CADENCE_XC/tools.lnx86/inca/bin/64bit
prepend PATH $CADENCE_XC/tools.lnx86/inca/bin
prepend PATH $CADENCE_XC/tools.lnx86/simvision/bin/64bit
prepend PATH $CADENCE_XC/tools.lnx86/simvision/bin
prepend PATH $CADENCE_AS/tools/bin
prepend PATH $CADENCE_AS/tools/assura/bin

# Conformal 25.2 defaults to the unlicensed CFMA_Basic AI product on this
# server.  The course license provides the classic Conformal_Asic (-L) mode.
alias lec "$CONFORMAL_HOME/bin/lec -L"
 
# Cadence runtime libraries.
if ($?LD_LIBRARY_PATH) then
    setenv LD_LIBRARY_PATH ${INCISIVE_BIN64}:${INCISIVE_BIN}:${CADENCE_IN}/tools.lnx86/lib:${LD_LIBRARY_PATH}
else
    setenv LD_LIBRARY_PATH ${INCISIVE_BIN64}:${INCISIVE_BIN}:${CADENCE_IN}/tools.lnx86/lib
endif
prepend LD_LIBRARY_PATH $CADENCE_IC/tools.lnx86/lib
prepend LD_LIBRARY_PATH $CADENCE_IC/tools.lnx86/lib/64bit
prepend LD_LIBRARY_PATH $CADENCE_IN/lib
prepend LD_LIBRARY_PATH $CADENCE_IN/tools.lnx86/lib
prepend LD_LIBRARY_PATH $CADENCE_XC/lib
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/lib
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/lib64
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/innovus/lib/64bit/  
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/IntegrityPlanner/jre/lib/server
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/mlpack/lib/64bit
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/Qt/v5/64bit/lib
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/vxe/lib/64bit
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/extraction/lib/64bit
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/zmq/lib/64bit
# prepend LD_LIBRARY_PATH $CADENCE_IV/tools.lnx86/TPtools/boost-1.81.0/lib/64bit
prepend LD_LIBRARY_PATH $CADENCE_IC/tools.lnx86/leveldb_1_2_2/lib64
prepend LD_LIBRARY_PATH $CADENCE_IC/tools.lnx86/Qt/v5/64bit/lib
prepend LD_LIBRARY_PATH $CADENCE_IC/tools.lnx86/sev/lib/64bit
prepend LD_LIBRARY_PATH $CADENCE_IC/tools.lnx86/extraction/lib/64bit
prepend LD_LIBRARY_PATH $CADENCE_IC/tools.lnx86/vsrf/oa_v22.62.009/lib/linux_rhel80_64/opt
prepend LD_LIBRARY_PATH $CADENCE_IC/tools.lnx86/TPtools/boost-1.81.0/lib/64bit
prepend LD_LIBRARY_PATH $CADENCE_IC/tools.lnx86/TPtools/libstdc++6-13.2.0/lib64

# NCSU FreePDK design kit used by the original setup.
setenv CDK_DIR /home/ee577@vlab.usc.edu/design_pdk/ncsu-cdk-1.6.0.beta

# Shared FreePDK45/OSU standard-cell libraries used by HW4 synthesis.
setenv NCSU45PDK_ROOT /tools/PDK/NCSU45PDK/FreePDK45
setenv OSU45_LIB_DIR $NCSU45PDK_ROOT/osu_soc/lib/files
 
# -------------------------------------------------------------------------
# Synopsys tools
# -------------------------------------------------------------------------
setenv SYNBASE /tools/synopsys
setenv SYNOPSYS_HS $SYNBASE/hspice/U-2023.03-SP2-3/hspice/linux64
setenv SYNOPSYS_DC $SYNBASE/syn/Y-2026.03
setenv SYNOPSYS_PT $SYNBASE/prime/Y-2026.03
setenv SYNOPSYS_CS $SYNBASE/syn/Y-2026.03
setenv SYNOPSYS_WV $SYNBASE/syn/Y-2026.03
setenv SYNOPSYS_TM $SYNBASE/syn/Y-2026.03
setenv VCS_HOME $SYNBASE/vcs/X-2025.06
setenv SYNOPSYS_STS $SYNBASE/syn/Y-2026.03
 
prepend PATH $SYNOPSYS_HS
prepend PATH $SYNOPSYS_HS/bin
prepend PATH $SYNOPSYS_DC/bin
prepend PATH $SYNOPSYS_PT/bin
prepend PATH $SYNOPSYS_CS/bin
prepend PATH $SYNOPSYS_WV/bin
prepend PATH $SYNOPSYS_TM/bin
prepend PATH $VCS_HOME/bin
prepend PATH $SYNOPSYS_STS/bin
 
# -------------------------------------------------------------------------
# Mentor/Siemens simulation tools
# -------------------------------------------------------------------------
setenv MENTOR_QCF /tools/siemens/questa_base
setenv QUESTA_HOME /tools/siemens/questa_base
prepend PATH $MENTOR_QCF/bin
prepend PATH $MENTOR_QCF/linux_x86_64
prepend PATH $QUESTA_HOME/bin
 
# Optional aliases from the original setup. Define them only when installed.
if (-x $SYNOPSYS_CS/ai_bin/cscope) alias cscope $SYNOPSYS_CS/ai_bin/cscope
if (-x $SYNOPSYS_CS/ai_bin/scope) alias scope $SYNOPSYS_CS/ai_bin/scope
