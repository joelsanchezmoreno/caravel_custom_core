#!/bin/bash

export MAGTYPE=mag ;
export BASE=/home/mk/zooz/ ;
export PDKPATH=$BASE/pdks/ef-skywater-s8/EFS8A ;

magic -dnull -noconsole -rcfile $PDKPATH/libs.tech/magic/current/EFS8A.magicrc <<EOF
load $1.mag
save $1.mag
writeall force
select top cell
extract style ngspice(si)
extract
ext2spice hierarchy on
ext2spice format ngspice
ext2spice cthresh infinite
ext2spice rthresh infinite
ext2spice renumber offS
ext2spice scale off
ext2spice blackbox on
ext2spice subcircuit top auto
ext2spice global off
ext2spice $1.ext
quit -noprompt
EOF
