#
#  Makefile --
#
#     Makefile for building import/export plug-ins.
#
#  Copyright (c) 2001-2009 Bjorn Gustavsson
#
#  See the file "license.terms" for information on usage and redistribution
#  of this file, and for a DISCLAIMER OF ALL WARRANTIES.
#
#     $Id: Makefile,v 1.25 2006/09/06 22:52:18 antoneos Exp $
#

.SUFFIXES: .erl .jam .beam .yrl .xrl .bin .mib .hrl .sgml .html .ps .3 .1 \
	.fig .dvi .tex .class .java .pdf .psframe .pscrop

ESRC=.
WINGS_INTL=../../intl_tools
EBIN=../../plugins/import_export
ERLC=erlc
WINGS_SRC=../../src
WINGS_EBIN=../../ebin
WINGS_E3D=../../e3d
ESDL=$(ESDL_PATH)

ifeq ($(TYPE),debug)
TYPE_FLAGS=-DDEBUG
else
TYPE_FLAGS=
endif

MODULES= \
	wpc_3ds \
	wpc_ai \
	wpc_bzw \
	wpc_collada \
	wpc_hlines \
	wpc_kerky \
	wpc_lwo \
	wpc_obj \
	wpc_pov \
	wpc_ps \
	wpc_rwx \
	wpc_stl \
	wpc_wrl \
	wpc_x \
	wpc_yafray

TARGET_FILES= $(MODULES:%=$(EBIN)/%.beam)

# ----------------------------------------------------
# FLAGS
# ----------------------------------------------------
ERL_COMPILE_FLAGS +=  -pa $(WINGS_EBIN) -pa $(WINGS_INTL) -I $(WINGS_INTL) -I $(WINGS_SRC) \
  -I $(WINGS_E3D) -I $(ESDL_PATH)/include -W $(TYPE_FLAGS) -pa $(ESDL_PATH)/ebin \
  +debug_info

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

# ----------------------------------------------------
# Dependencies
# ----------------------------------------------------

$(TARGET_FILES): $(WINGS_E3D)/e3d.hrl

