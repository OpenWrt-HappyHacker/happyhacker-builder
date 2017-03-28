#!/bin/bash
if [ "`echo profiles/*/`" != "profiles/*/" ]
then
  echo
  echo "The following profiles are available:"
  echo
  for i in profiles/*/
  do
    i=$(echo "$i" | sed "s/^profiles/bin/")
    i=${i::-1}
    echo "\$ make $i"
  done
  echo
else
  echo
  echo "ERROR: no profiles available"
  echo
fi

