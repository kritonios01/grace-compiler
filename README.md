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

```
##### To compile the project:
> Before you proceed make sure that the llvm compiler in your computer (*llc*) for LLVM 16 is named llc-16. If not, either create a symbolic link or go to llvm_compiler/src/main.ml at line 44 and adjust the command accordingly 
```
export GRC_LIB_PATH="..../grace-compiler/lib/lib.a"
cd llvm_compiler
eval $(opam env --switch grcc_19604)
dune build --profile release @install
cp _build/default/src/main.exe ./grcc
```
> After these steps the compiler executable *grcc* should be located in the llvm_compiler directory. This executable can be relocated anywhere on the computer and it will work as long as GRC_LIB_PATH is defined in the shell environemnt. 