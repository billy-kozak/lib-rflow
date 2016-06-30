#!/usr/bin/make -f
###############################################################################
# Copyright (C) 2016  Billy Kozak                                             #
#                                                                             #
# This file is part of lib-rflow                                              #
#                                                                             #
# This program is free software: you can redistribute it and/or modify        #
# it under the terms of the GNU General Public License as published by        #
# the Free Software Foundation, either version 3 of the License, or           #
# (at your option) any later version.                                         #
#                                                                             #
# This program is distributed in the hope that it will be useful,             #
# but WITHOUT ANY WARRANTY; without even the implied warranty of              #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the               #
# GNU General Public License for more details.                                #
#                                                                             #
# You should have received a copy of the GNU General Public License           #
# along with this program.  If not, see <http://www.gnu.org/licenses/>.       #
###############################################################################
###############################################################################
#                                    VARS                                     #
###############################################################################
CXX := g++
LD  := g++

CFLAGS += -Wall -std=c++11 -fpic
LDFLAGS += -shared -Wall

PROJECT := lib-rflow.so

NO_DEPS_TARGETS += clean directories dir_clean
###############################################################################
#                                 BUILD DIRS                                  #
###############################################################################
BUILD_DIR   := obj
EXE_DIR     := bin
ASM_GEN_DIR := asm_gen

SRC_TREE += src

INC_DIRS += inc
SRC_DIRS += src
###############################################################################
#                                 BUILD FILES                                 #
###############################################################################
C_PATHS   += $(foreach dir, $(SRC_DIRS),$(wildcard $(dir)/*.cpp))

C_FILES   += $(foreach f, $(C_PATHS),$(notdir $(f)))
OBJ_FILES += $(foreach f,$(C_FILES),$(BUILD_DIR)/$(patsubst %.cpp,%.o,$(f)))
DEP_FILES += $(foreach f,$(C_FILES),$(BUILD_DIR)/$(patsubst %.cpp,%.d,$(f)))
ASM_GEN   += $(foreach f,$(C_FILES),$(ASM_GEN_DIR)/$(patsubst %.cpp,%.s,$(f)))

LIBS = -lrt -lm

BINARY := $(EXE_DIR)/$(PROJECT)

INCLUDES += $(foreach f,$(INC_DIRS),-I$(f))

CFLAGS += $(INCLUDES)

vpath %.cpp $(SRC_DIRS)

C_DIRS += $(SRC_DIRS) $(INC_DIRS)

CLEAN_FILES += $(foreach dir,$(C_DIRS),$(wildcard $(dir)/*~))
CLEAN_FILES += $(foreach dir,$(C_DIRS),$(wildcard $(dir)/*\#))
CLEAN_FILES += $(wildcard Makefile~)
CLEAN_FILES += $(wildcard $(BUILD_DIR)/*) $(wildcard $(EXE_DIR)/*)
CLEAN_FILES += $(wildcard $(ASM_GEN_DIR)/*)
###############################################################################
#                                   TARGETS                                   #
###############################################################################
all: optomized

debug: CFLAGS += -DDEBUG=1 -g
debug: LDFLAGS += -g
debug: $(BINARY)

optomized: CFLAGS += -DNDEBUG=1 -march=native -g -Os -flto
optomized: LDFLAGS += -march=native -g -Os -flto
optomized: $(BINARY)

asg_gen: CFLAGS += -fverbose-asm
asm_gen: CFLAGS += -DNDEBUG=1 -march=native -Os -flto
asm_gen: $(ASM_GEN)

directories: $(BUILD_DIR)/.dir_dummy $(EXE_DIR)/.dir_dummy

%.dir_dummy:
	mkdir -p $(dir $(@))
	@touch $(@)

$(BUILD_DIR)/%.d: %.cpp | $(BUILD_DIR)/.dir_dummy
	$(CXX) $(CFLAGS) -MF $@ -M -MT "$(patsubst %.d,%.o,$@) $@" $<

$(BUILD_DIR)/%.o: %.cpp | $(BUILD_DIR)/.dir_dummy
	$(CXX) $(CFLAGS) -c $< -o $@

$(ASM_GEN): $(ASM_GEN_DIR)/%.s : %.c | $(ASM_GEN_DIR)/.dir_dummy
	$(CXX) $(CFLAGS) -S $< -o $@

$(BINARY): $(OBJ_FILES) | $(EXE_DIR)/.dir_dummy
	$(LD) $(LDFLAGS) $^ $(LIBS) -o $@

clean:
	rm -f $(CLEAN_FILES)

dir_clean:
	rm -rf $(BUILD_DIR) $(EXE_DIR) $(ASM_GEN_DIR)

ifeq (,$(filter $(MAKECMDGOALS), $(NO_DEPS_TARGETS)))

#next two conditonals prevent make from running on dry run or when
#invoked for tab-completion
ifneq (n,$(findstring n,$(firstword $(MAKEFLAGS))))
ifneq (p,$(findstring p,$(firstword $(MAKEFLAGS))))
-include $(DEP_FILES)
endif
endif


endif
