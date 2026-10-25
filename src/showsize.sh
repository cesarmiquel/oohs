#!/bin/bash

size=$(ls -l ../fp26.com | awk -F ' ' '{print $5}')

echo "-------------------"
echo "SIZE:   $size bytes"
echo "-------------------"
echo
