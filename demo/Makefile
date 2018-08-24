ELM_MAKE=elm make
ELM_PACKAGE=elm

OUT_DIR=../docs/demo
TARGET=main.js

CSSes=$(wildcard ./*.css)
CSS_OUTS=$(CSSes:%=$(OUT_DIR)/%)

PORTS_SRC_DIR=./Ports
PORTS_OUT_DIR=$(OUT_DIR)/ports
PORTS_JSes=$(notdir $(wildcard $(PORTS_SRC_DIR)/*.js))
PORTS_JS_OUTS=$(PORTS_JSes:%=$(PORTS_OUT_DIR)/%)

HTMLs=$(wildcard ./*.html)
HTML_OUTS=$(HTMLs:%=$(OUT_DIR)/%)


$(warning PORTS_JSes = $(PORTS_JSes))
$(warning CSSes      = $(CSSes))
$(warning HTMLs      = $(HTMLs))


.PHONY: all env clean $(OUT_DIR)/$(TARGET)

all: $(OUT_DIR)/$(TARGET) $(CSS_OUTS) $(PORTS_JS_OUTS) $(HTML_OUTS)


$(OUT_DIR)/%.html: %.html
	cp $*.html $(OUT_DIR)/$*.html

$(OUT_DIR)/%.css: %.css
	cp $*.css $(OUT_DIR)/$*.css

$(PORTS_OUT_DIR)/%.js: $(PORTS_SRC_DIR)/%.js
	mkdir -p $(PORTS_OUT_DIR)
	cp $(PORTS_SRC_DIR)/$*.js $(PORTS_OUT_DIR)/$*.js

env:
	$(ELM_PACKAGE) install
	mkdir -p $(OUT_DIR)
	mkdir -p $(PORT_OUT_DIR)

clean:
	rm -rf $(OUT_DIR)


$(OUT_DIR)/$(TARGET): Main.elm
	$(ELM_MAKE) Main.elm --output $(OUT_DIR)/$(TARGET)


