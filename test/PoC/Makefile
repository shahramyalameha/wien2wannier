### wien2wannier/test/Poc/Makefile
###
###    wien2wannier/test/PoC/Makefile
###
### Copyright 2016 Elias Assmann

-include ../../make.sys

ifndef WIENROOT_TEST
   $(error WIENROOT_TEST must be set (see make.sys.example))
endif

CASES=$(subst /,, $(wildcard */))

.ONESHELL:
SHELL=/bin/bash
.SHELLFLAGS = -ec

.PHONY: all clean $(CASES)

all: $(CASES)

$(CASES):
	@export WIENROOT=$(WIENROOT_TEST) PATH=$(WIENROOT_TEST):$$PATH
	./PoC.sh $@

clean:
	@for d in $(CASES); do
	   git clean -f $d
	done

	rm -rf */W

