##########################################################################
#                                                                        #
# JPEG codec Testsuite                                                   #
# (C) 2002 Richard Herveille   richard@asics.ws                          #
#                                                                        #
# v.01                                                                   #
#                                                                        #
##########################################################################

all: sim
SHELL = /bin/sh
MS="-s"

##########################################################################
#
# DUT Sources
#
##########################################################################
JPEG_SRC_DIR=	../../../rtl/verilog
DCT_SRC_DIR=	../../../../dct/rtl/verilog
QNR_SRC_DIR=	../../../../qnr/rtl/verilog
RLE_SRC_DIR=	../../../../run_length_enc/rtl/verilog

_TARGETS_=	$(JPEG_SRC_DIR)/jpeg_encoder.v	\
		$(DCT_SRC_DIR)/dct_mac.v	\
		$(DCT_SRC_DIR)/dct_syn.v	\
		$(DCT_SRC_DIR)/dctub.v		\
		$(DCT_SRC_DIR)/dctu.v		\
		$(DCT_SRC_DIR)/dct.v		\
		$(DCT_SRC_DIR)/zigzag.v		\
		$(DCT_SRC_DIR)/fdct.v		\
		$(QNR_SRC_DIR)/div_su.v		\
		$(QNR_SRC_DIR)/div_uu.v		\
		$(QNR_SRC_DIR)/jpeg_qnr.v	\
		$(RLE_SRC_DIR)/jpeg_rle1.v	\
		$(RLE_SRC_DIR)/jpeg_rzs.v	\
		$(RLE_SRC_DIR)/jpeg_rle.v



##########################################################################
#
# Test Bench Sources
#
##########################################################################
_TOP_=bench_top
TB_SRC_DIR=../../../bench/verilog
_TB_=		$(TB_SRC_DIR)/bench_top.v

##########################################################################
#
# Misc Variables
#
##########################################################################

INCDIR="-INCDIR ./$(TB_SRC_DIR)/ -INCDIR ./$(JPEG_SRC_DIR)/ -INCDIR ./$(DCT_SRC_DIR)/ \
        -INCDIR ./$(QNR_SRC_DIR)/ -INCDIR ./$(RLE_SRC_DIR)/"
LOGF=-LOGFILE .nclog
NCCOMMON=-CDSLIB ncwork/cds.lib -HDLVAR ncwork/hdl.var -NOCOPYRIGHT

##########################################################################
#
# Make Targets
#
##########################################################################
simw:
	@$(MAKE) -s sim ACCESS="-ACCESS +r " WAVES="-DEFINE WAVES"

ss:
	signalscan -do waves/waves.do -waves waves/waves.trn &

sim:
	@echo ""
	@echo "----- Running NCVLOG ... ----------"
	@$(MAKE) $(MS) vlog				\
		TARGETS="$(_TARGETS_)"			\
		TB="$(_TB_)"				\
		INCDIR=$(INCDIR)			\
		WAVES="$(WAVES)"
	@echo ""
	@echo "----- Running NCELAB ... ----------"
	@$(MAKE) $(MS) elab				\
		ACCESS="$(ACCESS)" TOP=$(_TOP_)
	@echo ""
	@echo "----- Running NCSIM ... ----------"
	@$(MAKE) $(MS) ncsim TOP=$(_TOP_)
	@echo ""


clean:
	rm -rf	./waves/*.dsn ./waves/*.trn		\
		ncwork/.inc* ncwork/inc*		\
		./verilog.* .nclog hal.log

##########################################################################
#
# NCVLOG
#
##########################################################################

vlog:
	ncvlog $(NCCOMMON) $(LOGF) 				\
		-WORK work $(WAVES) $(TB) $(TARGETS) $(INCDIR)

##########################################################################
#
# NCELAB
#
##########################################################################

elab:
	ncelab	$(NCCOMMON) $(LOGF) -APPEND_LOG 		\
		-WORK work $(ACCESS) -NOTIMINGCHECKS		\
		work.$(TOP)

##########################################################################
#
# NCSIM
#
##########################################################################

ncsim:
	ncsim	$(NCCOMMON) $(LOGF) -APPEND_LOG			\
		-EXIT -ERRORMAX 10 work.$(TOP)


