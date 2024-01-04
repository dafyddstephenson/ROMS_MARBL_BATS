#!/bin/bash

################################################################################
# This "from scratch" run begins from a generated initial condition using BGC
# data from CESM. It runs for one day with 36 second time steps to stabilise the
# run, generating a restart file from which a longer time step can be used
# (`fromrestart_run.sh`).
################################################################################

## Set environment variables
source ~/.ROMS 
NP_XI=4; # from code/param.opt
NP_ETA=2;

rm roms
ln -s code/roms .

## Check which BGC engine we're using
if grep -q "\!\# define BIOLOGY_BEC2" code/cppdefs.opt; 
then
    PREFIX=MARBL
else
    PREFIX=BEC
fi

# Split the initial and boundary conditions for use on multiple CPUs (default 8)
rundir=$(pwd)
cd INPUT/
mkdir PARTED/
for X in {\
roms_bry_2012.nc,roms_bry_bgc_"${PREFIX}".nc,roms_frc.201112.nc,\
roms_frc.201201.nc,roms_frc_bgc.nc,roms_grd.nc,\
roms_ini_"${PREFIX}".nc};do
    if [ -e PARTED/"${X/.nc}".0.nc ];then
	echo "INPUT/${X} appears to have already been partitioned. Continuing."
	continue
    else
    partit "${NP_XI}" "${NP_ETA}" "${X}";
    mv -v "${X/.nc}".?.nc PARTED/
    fi
done
cd ${rundir}

mpirun -n 8 ./roms ./roms.in_"${PREFIX}"_fromscratch 


echo "MAIN RUN DONE"
echo "########################################################################"

for X in ${PREFIX}_{rst,his,bgc_dia,bgc}.*.0.nc; do
    ncjoin ${X/.0.nc}.?.nc
    if [ -e ${X/.0.nc}.nc ]; then
	rm ${X/.0.nc}.?.nc
    fi
done

cd INPUT
ln -s ../"${PREFIX}"_rst.20120102120000.nc .
partit "${NP_XI}" "${NP_ETA}" "${PREFIX}"_rst.20120102120000.nc
mv "${PREFIX}"_rst.20120102120000.?.nc PARTED/
