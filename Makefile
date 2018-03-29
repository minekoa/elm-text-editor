ELM_MAKE=elm-make
ELM_PACKAGE=elm-package
ELM_TEST=elm-test

SRC_DIR=src
TARGET=main.js

.PHONY: all env compile release clean

test:
	$(ELM_TEST)

env:
	$(ELM_PACKAGE) install





