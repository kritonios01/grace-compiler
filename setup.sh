opam update
opam switch create grcc_19604 4.14.2+options

eval $(opam env --switch grcc_19604)

opam install menhir llvm.16.0.6+nnp -y

cd lib
gcc -c lib/lib.c -o lib/lib.o
ar rcs lib/lib.a lib/lib.o