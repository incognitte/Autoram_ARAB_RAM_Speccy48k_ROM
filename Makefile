\
# ArabRAM ROM reassembly — build with sjasmplus
# https://github.com/z00m128/sjasmplus
#
# Usage:
#   make              # build ArabRAM_regenerated.ROM
#   make verify       # build, then byte-compare against rom/ArabRam.rom
#   make clean        # remove build output

SJASMPLUS ?= tools/sjasmplus
SRC        = ArabRAM.asm
SRC_FILES  = $(SRC) $(wildcard src/*.asm)
OUT        = ArabRAM_regenerated.ROM
REFERENCE  = rom/ArabRam.rom

.PHONY: all verify clean sjasmplus-check

all: $(OUT)

$(OUT): $(SRC_FILES)
	$(SJASMPLUS) $(SRC) --raw=$(OUT)

verify: $(OUT)
	@cmp $(OUT) $(REFERENCE) && echo "OK: $(OUT) is byte-identical to $(REFERENCE)"

sjasmplus-check:
	@which $(SJASMPLUS) > /dev/null 2>&1 && echo "sjasmplus found: $$(which $(SJASMPLUS))" || \
	  (echo "sjasmplus not found on PATH. See README.md 'Getting sjasmplus' section." && exit 1)

clean:
	rm -f $(OUT)
