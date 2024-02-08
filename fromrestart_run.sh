#!/bin/bash

################################################################################
# This "fromrestart" run begins one day later than the "fromscratch" run,
# allowing the use of a ROMS-generated restart file. It is assumed the user has
# already run ./fromscratch_run.sh to produce {MARBL,BEC}_rst.20120102120000.nc
################################################################################

## Set environment variables
source ~/.ROMS 
NP_XI=4; # from code/param.opt
NP_ETA=2;

if grep -q "\!\# define BIOLOGY_BEC2" code/cppdefs.opt;
then
    if grep -q "\!\# define MARBL\b" code/cppdefs.opt;
    then
	PREFIX=NOBGC # No biology
    elif grep -q "\# define MARBL\b" code/cppdefs.opt;
    then
	 PREFIX=MARBL # BGC with MARBL
    fi
elif grep -q "\# define BIOLOGY_BEC2" code/cppdefs.opt;
then
    PREFIX=BEC # BGC with BEC
fi

if [ ! -e RST/${PREFIX}_rst.20120103120000.0.nc ];then
    echo "Restart file for Jan 3rd 2012 not found"
    echo "Run from scratch using INPUT/roms_ini_${PREFIX} first"
    echo "(script fromscratch_run.sh)"
    exit 1
fi

mpirun -n 8 ./roms ./roms.in_"${PREFIX}"


echo "MAIN RUN DONE"
echo "########################################################################"

cp ${PREFIX}_rst.*.?.nc RST/

for X in ${PREFIX}_???.*.0.nc; do
    ncjoin ${X/.0.nc}.?.nc
    if [ -e ${X/.0.nc}.nc ]; then
	rm ${X/.0.nc}.?.nc
    fi
done
