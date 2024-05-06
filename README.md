## Grace Compiler

### Dependencies
- opam 2.1+
- LLVM 16

### Quickstart
##### Go to root of this repo and run:
```
./setup.sh
```
##### To compile the project:
```
cd llvm_compiler
dune build --profile release @install
cp _build/default/src/main.exe ./grcc.exe
```


## Dependencies: ocamllex, menhir, llvm 15.0.7

### To compile lib
```
gcc -c lib/lib.c -o lib/lib.o
ar rcs lib/lib.a lib/lib.o
```
