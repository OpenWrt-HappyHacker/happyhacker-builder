#!/bin/bash
set -e
rm -fr ./bin/*
if [ -e .git/ ]
then
  git checkout -- bin/
else
  mkdir bin
  chmod 777 bin
fi
