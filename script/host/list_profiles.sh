#!/bin/bash
for i in profiles/*/
do
    i=$(echo "$i" | sed "s/^profiles/bin/")
    i=${i::-1}
    echo "$i"
done

