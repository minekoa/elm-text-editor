ELM_MAKE=elm-make
ELM_PACKAGE=elm-package
ELM_TEST=elm-test
MAKE=make

SRC_DIR=src
TARGET=main.js
subdirs=demo

.PHONY: all env clean $(subdirs)


all: $(subdirs) test

demo:
	cd demo
	$(MAKE)
	cd ..

$(subdirs):
	$(MAKE) -C $@

test:
	$(ELM_TEST)

env:
	$(ELM_PACKAGE) install

clean:
	rm -rf docs




