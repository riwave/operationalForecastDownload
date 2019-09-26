#!/bin/bash

################################################################
#
#     Script to fetch Global Ensemble forecasts (bias corrected)
#     via CURL and WGET- cycle 00Z
#     NCEP (GEFS), Canadian Meteorological Center (CMCE) and 
#     US Navy Fleet Numerical Meteorology and Ocenography Center (FENS) 
#       using WGRIB2, NCO, and CDO for post-processing
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   A copy of the GNU General Public License is provided at
#   http://www.gnu.org/licenses/
#
#   Ricardo Campos (REMO/CHM, IST/CENTEC) & Ronaldo Palmeira (IAG/USP)
#
#   riwave@gmail.com , https://github.com/riwave
#     https://www.linkedin.com/in/ricardo-martins-campos-451a45122/
#     https://www.researchgate.net/profile/Ricardo_Campos20
#
#   Version 1.0:  07/2016
#   Version 2.0:  08/2019
################################################################

source /etc/bash.bashrc
# directory where this code as well as get_grib.pl and get_inv.pl are saved
DIRS=/media/chico/op/ftpget/model/scripts
# directory where directory will be created and filed will be saved
DIR=/media/data/forecast/model/opftp
# e-mail info for automatic messages in case of error during download
emaildest=''
# email source
emailfonte=''
senha=''

# server address
SERVER=https://www.ftp.ncep.noaa.gov

# limits for domain selection
latmin=-77.5
latmax=90.
lonmin=-102.
lonmax=30.
#
UGRD=":UGRD:10 m above ground:"
VGRD=":VGRD:10 m above ground:"
VARSGETGEFS="$UGRD|$VGRD"

# initial date cycle for the ftp
ANO=`date +%Y`
MES=`date +%m`
DIA=`date +%d`
HORA="00" # first cycle 00Z

cd $DIR
# create directory
mkdir -p $DIR/gens_bc.$ANO$MES$DIA$HORA
# all information about fetching the grib2 files will be saved in the log file 
echo "  " > $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA

# hours of forecast to be dowloaded
horas=`seq -f "%02g" 0 12 384`
# number of ensembles
ensbl="`seq -f "%02g" 0 1 20`"

for h in $horas;do
  for e in $ensbl;do
    # GENS GEFS (1X1, 6h) --------------------------------------------------
    echo "  " >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
    echo " ======== GENS GEFS Forecast: $ANO$MES$DIA$HORA  $h ========" >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 
    # size TAM and tries TRIES will control the process
    TAM=0
    TRIES=1
    # while file has a lower size the expected or attemps are less than 130 (almos 11 hours trying) it does:
    # 350000
    while [ $TAM -lt 400000 ] && [ $TRIES -le 130 ]; do
      # sleep 5 minutes between attemps
      if [ ${TRIES} -gt 5 ]; then
        sleep 300
      fi
      # --- CURL VIA WWW.FTP.NCEP.NOAA.GOV --- #
      if [ ${TAM} -lt 400000 ]; then
          echo "  " >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          echo " attempt number: $TRIES" >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          echo "  " >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          # main line where get_inv.pl and get_grib.pl are used to fech the grib2 file  
          if [ ${e} == 00 ]; then
             $DIRS/get_inv.pl $SERVER/data/nccf/com/naefs/prod/gefs.$ANO$MES$DIA/$HORA/pgrb2ap5_bc/gec${e}.t${HORA}z.pgrb2a.0p50_bcf"$(printf "%03d" $h)".idx | egrep "($VARSGETGEFS)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/naefs/prod/gefs.$ANO$MES$DIA/$HORA/pgrb2ap5_bc/gec${e}.t${HORA}z.pgrb2a.0p50_bcf"$(printf "%03d" $h)" $DIR/gens_bc.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2fbc"$(printf "%03d" $h)".grb2 >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1         
          else
             $DIRS/get_inv.pl $SERVER/data/nccf/com/naefs/prod/gefs.$ANO$MES$DIA/$HORA/pgrb2ap5_bc/gep${e}.t${HORA}z.pgrb2a.0p50_bcf"$(printf "%03d" $h)".idx | egrep "($VARSGETGEFS)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/naefs/prod/gefs.$ANO$MES$DIA/$HORA/pgrb2ap5_bc/gep${e}.t${HORA}z.pgrb2a.0p50_bcf"$(printf "%03d" $h)" $DIR/gens_bc.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2fbc"$(printf "%03d" $h)".grb2 >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1         
          fi
          # test if the downloaded file exists
          test -f $DIR/gens_bc.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2fbc"$(printf "%03d" $h)".grb2 >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
          TE=$?
          if [ ${TE} -eq 1 ]; then
            TAM=0
          else
            # check size of each file
            TAM=`du -sb $DIR/gens_bc.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2fbc"$(printf "%03d" $h)".grb2 | awk '{ print $1 }'` >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
          fi
      fi

      TRIES=`expr $TRIES + 1`
    done
    sleep 2
  done
  sleep 5
done
sleep 30


# Check the entire download, as a whole, inside the directory
TAMD=`du -sb $DIR/gens_bc.$ANO$MES$DIA$HORA | awk '{ print $1}'` >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
TAMDW=`du -sh $DIR/gens_bc.$ANO$MES$DIA$HORA | awk '{ print $1}'` >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
echo " " >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
echo " " >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
echo "---- Final Status ----" >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
NANO=`date '+%Y'`
NMES=`date '+%m'`
NDIA=`date '+%d'`
NHORA=`date '+%H'`
NMINUTO=`date '+%M'`
if [ ${TAMD} -gt 200000000 ]; then
  echo " Entire Download successfully completed, no  problem found. Total size: $TAMDW" >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA  
  echo " Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO" >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
else
  echo " ATTENTION! Some error has happened during the download. Total size: $TAMDW" >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
  echo " Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO" >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 
  # Send e-mail in case of problems,  see /media/rmc/bento/Library/Manuals_Tips/enviandoemail
cat > email.txt << EOF
To: $emaildest
Subject: GENS BC Download Problem

ATTENTION! Some error has happened during the GENS BC download. Total size: $TAMDW
In: $DIR/gens_bc.$ANO$MES$DIA$HORA
Script: $DIRS/get_gens_c00.sh
Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO
EOF
  /usr/sbin/ssmtp $emaildest -au$emailfonte -ap$senha < email.txt >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1	
  rm -f email*	
fi
echo "----------------------" >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA


# Cleaning 
# --- Remove directories older than 5 days
cd $DIR
# find gens_bc.?????????? -ctime +4 -type d | xargs rm -rf >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1 

# Post-processing: select area and reduces resolution, in order to save disk space. ------------------
echo " " >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
echo " Post-Processing. select area and reduces resolution " >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA

for h in $horas;do
  for e in $ensbl;do

     # GEFS
     arqn=$DIR/gens_bc.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2fbc"$(printf "%03d" $h)"
     test -f ${arqn}.grb2 >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
     TE=$?
     if [ ${TE} -eq 1 ]; then
       echo " File ${arqn}.grb2 does not exist. Failed to download " >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
     else
       /usr/local/grib2/wgrib2/wgrib2 ${arqn}.grb2 -netcdf ${arqn}.saux.nc
       /usr/bin/cdo sellonlatbox,-180,180,-90,90 ${arqn}.saux.nc ${arqn}.saux1.nc
       /usr/bin/ncks -4 -L 1 -d latitude,${latmin},${latmax} ${arqn}.saux1.nc ${arqn}.saux2.nc
       /usr/bin/ncks -4 -L 1 -d longitude,${lonmin},${lonmax} ${arqn}.saux2.nc ${arqn}.saux3.nc
       /usr/bin/ncatted -a _FillValue,,o,f,NaN ${arqn}.saux3.nc
       /usr/bin/ncks --ppc default=.$dp ${arqn}.saux3.nc ${arqn}.nc
       rm -f ${arqn}.grb2
       rm ${arqn}.saux*
       echo " Converted file ${arqn} to netcdf with success, and reduced size. " >> $DIR/gens_bc.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
     fi

  done
done


# Merge all netcdf files
for e in $ensbl;do
  /usr/bin/ncecat $DIR/gens_bc.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2fbc*.nc -O $DIR/gens_bc.$ANO$MES$DIA$HORA/gefs.$ANO$MES$DIA$HORA.m${e}.pgrb2ap5.nc
  rm -f $DIR/gens_bc.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2fbc*.nc
done

# permissions and groups
# chgrp amadmin -R $DIR/gfs.$ANO$MES$DIA$HORA
chmod -R 775 $DIR/gens_bc.$ANO$MES$DIA$HORA

