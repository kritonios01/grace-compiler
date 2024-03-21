#!/bin/bash

file=$1


dune exec --profile release _build/default/src/main.exe < "$file"
llc-15 -opaque-pointers llvm_ir.ll -o out.s
clang -no-pie out.s ../lib.a -o exec