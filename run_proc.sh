#! /usr/bin/bash
/usr/bin/flex -L ./pcl-hpgl.l
sed -i '/#line/d' ./pcl-hpgl-scanner.cpp