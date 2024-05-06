## Grace Compiler

### Dependencies
- opam 2.1+
- LLVM 16
- clang

### Quickstart
> Make sure you have clang and opam installed before you proceed. Everything else is handled by setup.sh.
##### Go to root of this repo and run:
```
./setup.sh
eval $(opam env --switch grcc_19604)
```
##### To compile the project:
```
cd llvm_compiler
dune build --profile release @install
cp _build/default/src/main.exe ./grcc.exe
```
