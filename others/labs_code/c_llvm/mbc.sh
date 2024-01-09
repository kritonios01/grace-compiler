#!/usr/bin/env bash

./mbc < $1 > arxeio.ll
llc -o arxeio.s arxeio.ll
clang -o a.out arxeio.s libminibasic.a
