#-------------------------------------------------
#
# Project created by QtCreator 2015-08-04T09:47:16
#
#-------------------------------------------------

include(flex.pri)
FLEXSOURCES = pcl-hpgl.l

QT       += core

QT       -= gui

TARGET = flexFun
CONFIG   += console
CONFIG   -= app_bundle

# Make some fake targets to generate the pcl-hpgl-scanner.*
#flexheader.target = ../flexFun/pcl-hpgl-scanner.h
#flexheader.depends = flexsource
#flexheader.commands = type nul >> ../flexFun/pcl-hpgl-scanner.h
#flexsource.target = ../flexFun/pcl-hpgl-scanner.cpp
#flexsource.depends = FORCE
#flexsource.commands = type nul >> ../flexFun/pcl-hpgl-scanner.cpp

## Define how to create the parser
##flex.target = ../flexFun/pcl-hpgl-scanner.h
#flex.depends = flexheader
#flex.commands = $$PWD/exec.bat $$PWD
#PRE_TARGETDEPS += ../flexFun/pcl-hpgl-scanner.h
#QMAKE_EXTRA_TARGETS += flexsource flexheader flex

TEMPLATE = app


SOURCES += main.cpp

DISTFILES += \
    flex.pri

