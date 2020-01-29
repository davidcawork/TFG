# SPDX-License-Identifier: (GPL-2.0 OR BSD-2-Clause)
#
# Modified archive of the xdp-project (github.com/xdp-project) repository 
# for purely academic purposes. 
#
# 	Author: David Carrascal <davidcawork@gmail.com>
# 	Date:   29 Jan 2011

CASES = $(wildcard case*) 
CASES_CLEAN = $(addsuffix _clean,$(CASES))

.PHONY: clean $(CASES) $(CASES_CLEAN)

all: $(CASES)
clean: $(CASES_CLEAN)

$(CASES):
	$(MAKE) -C $@

$(CASES_CLEAN):
	$(MAKE) -C $(subst _clean,,$@) clean
