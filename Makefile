ELM_MAKE=elm-make
ELM_PACKAGE=elm-package
ELM_TEST=elm-test
MAKE=make

SRC_DIR=src
TARGET=main.js
subdirs=demo example/markdown example/defaultStyles

.PHONY: all env clean package $(subdirs)


all: $(subdirs) test package

$(subdirs):
	$(MAKE) -C $@

test:
	$(ELM_TEST)

env:
	$(ELM_PACKAGE) install

clean:
	rm -rf docs

package:
	$(ELM_MAKE) --docs=documentation.json


