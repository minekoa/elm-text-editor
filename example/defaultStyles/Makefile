ELM_MAKE=elm make
ELM_PACKAGE=elm-package

OUT_DIR=../../docs/example/defaultStyles
TARGET=main.js

CSSes=$(wildcard ./*.css)
CSS_OUTS=$(CSSes:%=$(OUT_DIR)/%)

HTMLs=$(wildcard ./*.html)
HTML_OUTS=$(HTMLs:%=$(OUT_DIR)/%)


$(warning CSSes      = $(CSSes))
$(warning HTMLs      = $(HTMLs))


.PHONY: all env clean $(OUT_DIR)/$(TARGET)

all: $(OUT_DIR)/$(TARGET) $(CSS_OUTS) $(HTML_OUTS)


$(OUT_DIR)/%.html: %.html
	cp $*.html $(OUT_DIR)/$*.html

$(OUT_DIR)/%.css: %.css
	cp $*.css $(OUT_DIR)/$*.css


env:
	$(ELM_PACKAGE) install
	mkdir -p $(OUT_DIR)

clean:
	rm -rf $(OUT_DIR)


$(OUT_DIR)/$(TARGET): Main.elm
	$(ELM_MAKE) Main.elm --output $(OUT_DIR)/$(TARGET)



