#-------------------------------------------------
#
# Project created by QtCreator 2015-08-04T09:47:16
#
#-------------------------------------------------

QT       += core

QT       -= gui

TARGET = flexFun
CONFIG   += console
CONFIG   -= app_bundle


# Define how to create the parser
flexheader.target = $$PWD/pcl-hpgl-scanner.h
flexheader.depends = FORCE
flexheader.commands = $$PWD/exec.bat $$PWD
PRE_TARGETDEPS += $$PWD/pcl-hpgl-scanner.h
QMAKE_EXTRA_TARGETS += flexheader

TEMPLATE = app


SOURCES += main.cpp pcl-hpgl-scanner.cpp
HEADERS += pcl-hpgl-scanner.h \
    pcl-hpgl.l

DEPENDPATH += $$PWD

