package=tyttp-json.ipkg
executable=tyttp-json
idris2=idris2
codegen=node

.PHONY: build clean repl install dev

build:
	bash -c 'time $(idris2) --build $(package) --codegen $(codegen)'

clean:
	rm -rf build

repl:
	rlwrap $(idris2) --repl $(package)

run: build
	bash -c 'time node build/exec/$(executable)'

install:
	$(idris2) --install $(package) --codegen $(codegen)

dev: clean
	find src/ -name *.idr | entr make run

dev-build: clean
	find src/ -name *.idr | entr make build
