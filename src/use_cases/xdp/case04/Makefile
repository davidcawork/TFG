# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
#
# Modified archive of the xdp-project (github.com/xdp-project) repository 
# for purely academic purposes. 
#
# 	Author: David Carrascal <davidcawork@gmail.com>
# 	Date:   07 Feb 2020

XDP_TARGETS  := prog_kern
USER_TARGETS := prog_user

LIBBPF_DIR = ../libbpf/src/
COMMON_DIR = ../common

COPY_LOADER := xdp_loader
COPY_STATS  := xdp_stats
EXTRA_DEPS := $(COMMON_DIR)/parsing_helpers.h

include $(COMMON_DIR)/common.mk
