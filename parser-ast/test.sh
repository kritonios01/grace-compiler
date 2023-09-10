#!/bin/sh
prog_dir='../examples/progs'

for entry in `ls $prog_dir`; do
	echo $entry
	./parser < $prog_dir/$entry
done
