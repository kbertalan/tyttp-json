package=tyttp-json.ipkg
executable=tyttp-json
idris2=idris2
codegen=node

.PHONY: build clean repl install dev

build:
	bash -c 'time pack build $(package)'

clean:
	rm -rf build

repl:
	pack --with-ipkg $(package) --rlwrap repl

run: build
	bash -c 'time node build/exec/$(executable)'

install:
	$(idris2) --install $(package) --codegen $(codegen)

dev: clean
	find src/ -name *.idr | entr make run

dev-build: clean
	find src/ -name *.idr | entr make build
