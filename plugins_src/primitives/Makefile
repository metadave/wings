#
#  Makefile --
#
#     Makefile for building plug-ins for primitives.
#
#  Copyright (c) 2001-2009 Bjorn Gustavsson
#
#  See the file "license.terms" for information on usage and redistribution
#  of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
#     $Id: Makefile,v 1.14 2006/08/02 22:44:40 antoneos Exp $
#

.SUFFIXES: .erl .jam .beam .yrl .xrl .bin .mib .hrl .sgml .html .ps .3 .1 \
	.fig .dvi .tex .class .java .pdf .psframe .pscrop

ESRC=.
WINGS_INTL=../../intl_tools
EBIN=../../plugins/primitives
ERLC=erlc
WINGS_SRC=../../src
WINGS_E3D=../../e3d
ESDL=$(ESDL_PATH)

ifeq ($(TYPE),debug)
TYPE_FLAGS=-DDEBUG
else
TYPE_FLAGS=
endif

MODULES= \
	wpc_bbox \
	wpc_image \
	wpc_knot \
	wpc_spiral \
	wpc_torus \
	wpc_plane \
	wpc_gear \
	wpc_ncube \
	wpc_geodome \
	wpc_tt

TARGET_FILES= $(MODULES:%=$(EBIN)/%.beam)

# ----------------------------------------------------
# FLAGS
# ----------------------------------------------------
ERL_COMPILE_FLAGS += -I $(WINGS_SRC) -I $(WINGS_E3D) -pa $(ESDL)/ebin \
  -W $(TYPE_FLAGS) -pa $(WINGS_INTL) -I $(WINGS_INTL) +debug_info

# ----------------------------------------------------
# Targets
# ----------------------------------------------------

opt debug:
	$(MAKE) TYPE=$@ common

template: opt
	erl -pa $(WINGS_INTL) -noinput -run tools generate_template_files $(EBIN)

lang: template
	cp *.lang $(EBIN)
	erl -pa $(WINGS_INTL) -noinput -run tools diff_lang_files $(EBIN)

common: $(TARGET_FILES)

clean:
	rm -f $(TARGET_FILES)
	rm -f core

$(EBIN)/%.beam: $(ESRC)/%.erl
	$(ERLC) $(ERL_COMPILE_FLAGS) -o$(EBIN) $<

$(EBIN)/wpc_image.beam $(EBIN)/wpc_tt.beam: $(WINGS_E3D)/e3d.hrl
