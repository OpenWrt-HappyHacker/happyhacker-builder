#!/bin/bash
if [ "`echo config/*/`" != "config/*/" ]
then
  echo
  echo "The following targets are available:"
  echo
  for i in config/*/
  do
    i=$(echo "$i" | sed "s/^config/bin/")
    i=${i::-1}
    echo "\$ make $i"
  done
  echo
else
  echo
  echo "ERROR: no targets available"
  echo
fi
