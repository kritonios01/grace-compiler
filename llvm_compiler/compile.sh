#!/bin/bash

file=$1


dune exec --profile release _build/default/src/main.exe < "$file"
llc-15  llvm_ir.ll -o out.s
clang -no-pie out.s ../libgrc.a -o exec

