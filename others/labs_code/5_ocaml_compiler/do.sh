#! /bin/bash

function die () {
  printf "FAILED!!!\n"
  rm -f a.*
  read -p "Press <ENTER> to continue...  "
  exit 1
}

while [ "$1" != "" ]; do
  f="${1/%.mba}"

  echo "--------------------------------------------------------------------"
  printf "%-40s" "$f"
  rm -f a.*
  ./minibasic < $f.mba > a.asm || die
  printf "success\n"

  dosbox run.bat -exit >& /dev/null

  shift
done

rm -f a.*

exit 0
