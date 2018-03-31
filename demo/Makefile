ELM_MAKE=elm-make
ELM_PACKAGE=elm-package

OUT_DIR=../docs
TARGET=main.js

CSSS=$(wildcard ./*.css)
CSS_OUTS=$(CSSS:%=$(OUT_DIR)/%)

.PHONY: all env $(OUT_DIR)/$(TARGET)

all: $(OUT_DIR)/$(TARGET) $(CSS_OUTS)
	cp index.html $(OUT_DIR)/index.html

$(OUT_DIR)/%.css: %.css
	cp $*.css $(OUT_DIR)/$*.css

env:
	$(ELM_PACKAGE) install
	mkdir -p $(OUT_DIR)


$(OUT_DIR)/$(TARGET): Main.elm
	$(ELM_MAKE) Main.elm --output $(OUT_DIR)/$(TARGET)


