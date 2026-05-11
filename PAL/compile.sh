#!/bin/bash

iverilog -g2005-sv -o pal_dc_down.vvp pal_dc_down_test.v pal_dc_down.v lpf.v

if [ $? -eq 0 ]; then
    vvp pal_dc_down.vvp
else
    echo "Ошибка"
    exit 1
fi
