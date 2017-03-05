#!/bin/bash
for i in config/*/
do
    i=$(echo "$i" | sed "s/^config/bin/")
    i=${i::-1}
    echo "$i"
done

