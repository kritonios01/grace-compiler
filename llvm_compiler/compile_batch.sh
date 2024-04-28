#!/bin/bash

dune exec --profile release _build/default/src/main.exe < "../examples/hello.grc"
llc-16 llvm_ir.ll -o out.s
clang -no-pie out.s ../lib.a -o exec

dune exec --profile release _build/default/src/main.exe < "../examples/hanoi.grc"
llc-16 llvm_ir.ll -o out.s
clang -no-pie out.s ../lib.a -o exec

dune exec --profile release _build/default/src/main.exe < "../examples/primes.grc"
llc-16 llvm_ir.ll -o out.s
clang -no-pie out.s ../lib.a -o exec

dune exec --profile release _build/default/src/main.exe < "../examples/strrev.grc"
llc-16 llvm_ir.ll -o out.s
clang -no-pie out.s ../lib.a -o exec

dune exec --profile release _build/default/src/main.exe < "../examples/bsort.grc"
llc-16 llvm_ir.ll -o out.s
clang -no-pie out.s ../lib.a -o exec