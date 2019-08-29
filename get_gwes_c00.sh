#!/bin/bash

################################################################
#
#    Script to fetch Global Wave Ensemble forecasts via CURL and WGET- cycle 00Z
#    NCEP (GEFS) and US Navy Fleet Numerical Meteorology and Ocenography Center (FENS) 
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
DIRS=/home/rmc/operacional/ftpdata/scripts
# directory where directory will be created and filed will be saved
DIR=/home/rmc/operacional/ftpdata/data
# e-mail info for automatic messages in case of error during download, FILL IN HERE
emaildest=''
# email source
emailfonte=''
senha=''

# server address
SERVER=https://www.ftp.ncep.noaa.gov
# ftp://ftpprd.ncep.noaa.gov/pub/data/nccf/com/

# limits for domain selection
latmin=-77.5
latmax=90.
lonmin=-102.
lonmax=30.
# list of variables in the .idx file  (0.5X0.5, 6h)
# https://www.nco.ncep.noaa.gov/pmb/products/wave/multi_1.glo_30m.t00z.grib2.shtml

#WH=":HTSGW:surface:"
#WP=":PERPW:surface:"
#VARSGET="$WH|$WP"
WH=":HTSGW:surface:|:WVHGT:surface:|:SWELL:1 in sequence:|:SWELL:2 in sequence:"
WP=":MWSPER:surface:|:PERPW:surface:|:WVPER:surface:|:SWPER:1 in sequence:|:SWPER:2 in sequence:"
WD=":DIRPW:surface:|:WVDIR:surface:|:SWDIR:1 in sequence:|:SWDIR:2 in sequence:"
VARSGET="$WH|$WP|$WD"

# initial date cycle for the ftp
ANO=`date +%Y`
MES=`date +%m`
DIA=`date +%d`
HORA="00" # first cycle 00Z

cd $DIR
# create directory
mkdir -p $DIR/gwes.$ANO$MES$DIA$HORA
# all information about fetching the grib2 files will be saved in the log file 
echo "  " > $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA

# number of ensembles
ensbl="`seq -f "%02g" 0 1 20`"
#
for e in $ensbl;do

  echo "  " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
  echo " ======== WW3 NCEP Ensemble Forecast: $ANO$MES$DIA$HORA ens $e ========" >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 
  # size TAM and tries TRIES will control the process
  TAM=0
  TRIES=1
  # while file has a lower size the expected or attemps are less than 130 (almos 11 hours trying) it does:
  while [ $TAM -lt 100000000 ] && [ $TRIES -le 130 ]; do
    # sleep 5 minutes between attemps
    if [ ${TRIES} -gt 5 ]; then
      sleep 300
    fi
    # --- CURL VIA WWW.FTP.NCEP.NOAA.GOV --- #
    if [ ${TAM} -lt 100000000 ]; then
       echo "  " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
       echo " attempt number: $TRIES" >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
       echo "  " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
       # main line where get_inv.pl and get_grib.pl are used to fech the grib2 file
       $DIRS/get_inv.pl $SERVER/data/nccf/com/wave/prod/gwes.$ANO$MES$DIA/gwes$e.glo_30m.t${HORA}z.grib2.idx | egrep "($VARSGET)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/wave/prod/gwes.$ANO$MES$DIA/gwes$e.glo_30m.t${HORA}z.grib2 $DIR/gwes.$ANO$MES$DIA$HORA/gwes$e.t${HORA}z.grib2 >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1         

     # test if the downloaded file exists
       test -f $DIR/gwes.$ANO$MES$DIA$HORA/gwes$e.t${HORA}z.grib2 >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1
       TE=$?
       if [ ${TE} -eq 1 ]; then
         TAM=0
       else
         # check size of each file
         TAM=`du -sb $DIR/gwes.$ANO$MES$DIA$HORA/gwes$e.t${HORA}z.grib2 | awk '{ print $1 }'` >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1
       fi
    fi

    TRIES=`expr $TRIES + 1`
  done

  echo "  " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
  echo " ======== WW3 US Navy Ensemble Forecast: $ANO$MES$DIA$HORA ens $e ========" >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 
  # size TAM and tries TRIES will control the process
  TAM=0
  TRIES=1
  # while file has a lower size the expected or attemps are less than 130 (almos 11 hours trying) it does:
  while [ $TAM -lt 2000000 ] && [ $TRIES -le 130 ]; do
    # sleep 5 minutes between attemps
    if [ ${TRIES} -gt 5 ]; then
      sleep 300
    fi
    # --- WGET VIA WWW.FTP.NCEP.NOAA.GOV --- #
    if [ ${TAM} -lt 2000000 ]; then

      wget  -d -c --tries=5 $SERVER/data/nccf/com/wave/prod/nfcens.$ANO$MES$DIA/HTSGW_$e.t00z.grib2 -O $DIR/gwes.$ANO$MES$DIA$HORA/nfcens$e.t${HORA}z.grib2 >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1
      sleep 10
      test -f $DIR/gwes.$ANO$MES$DIA$HORA/nfcens$e.t${HORA}z.grib2 >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1 
      TE=$?
      if [ ${TE} -eq 1 ]; then
        TAM=0
      else
        # check size of each file
        TAM=`du -sb $DIR/gwes.$ANO$MES$DIA$HORA/nfcens$e.t${HORA}z.grib2 | awk '{ print $1 }'` >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1
      fi
    fi
    TRIES=`expr $TRIES + 1`
  done
done


# Check the entire download, as a whole, inside the directory
TAMD=`du -sb $DIR/gwes.$ANO$MES$DIA$HORA | awk '{ print $1}'` >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1
TAMDW=`du -sh $DIR/gwes.$ANO$MES$DIA$HORA | awk '{ print $1}'` >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1
echo " " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
echo " " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
echo "---- Final Status ----" >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
NANO=`date '+%Y'`
NMES=`date '+%m'`
NDIA=`date '+%d'`
NHORA=`date '+%H'`
NMINUTO=`date '+%M'`
if [ ${TAMD} -gt 2000000000 ]; then
  echo " Entire Download successfully completed, no  problem found. Total size: $TAMDW" >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA  
  echo " Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO" >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
else
  echo " ATTENTION! Some error has happened during the download. Total size: $TAMDW" >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
  echo " Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO" >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 
  # Send e-mail in case of problems,  see /media/rmc/bento/Library/Manuals_Tips/enviandoemail
cat > email.txt << EOF
To: $emaildest
Subject: WW3 Ensemble Download Problem

ATTENTION! Some error has happened during the WW3 download. Total size: $TAMDW
In: $DIR/gwes.$ANO$MES$DIA$HORA
Script: $DIRS/get_gwes_c00.sh
Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO
EOF
  /usr/sbin/ssmtp $emaildest -au$emailfonte -ap$senha < email.txt >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1	
  rm -f email*	
fi
echo "----------------------" >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA


# Cleaning 
# --- Remove directories older than 5 days
cd $DIR
# find gwes.?????????? -ctime +4 -type d | xargs rm -rf >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1 

# Post-processing: select area and reduces resolution, in order to save disk space. ------------------
echo " " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
echo " Post-Processing. select area and reduces resolution " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA

for e in $ensbl;do

     # GWES
     arqn=$DIR/gwes.$ANO$MES$DIA$HORA/gwes$e.t${HORA}z
     test -f ${arqn}.grib2 >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1
     TE=$?
     if [ ${TE} -eq 1 ]; then
       echo " File ${arqn}.grib2 does not exist. Failed to download " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
     else
       /usr/local/grib2/wgrib2/wgrib2 ${arqn}.grib2 -netcdf ${arqn}.saux.nc
       /usr/bin/cdo sellonlatbox,-180,180,-90,90 ${arqn}.saux.nc ${arqn}.saux1.nc
       /usr/bin/ncks -4 -L 1 -d latitude,${latmin},${latmax} ${arqn}.saux1.nc ${arqn}.saux2.nc
       /usr/bin/ncks -4 -L 1 -d longitude,${lonmin},${lonmax} ${arqn}.saux2.nc ${arqn}.saux3.nc
       /usr/bin/ncatted -a _FillValue,,o,f,NaN ${arqn}.saux3.nc
       /usr/bin/ncks --ppc default=.$dp ${arqn}.saux3.nc $DIR/gwes.$ANO$MES$DIA$HORA/gwes$e.glo_30m.$ANO$MES$DIA$HORA.nc
       rm -f ${arqn}.grib2
       rm ${arqn}.saux*
       echo " Converted file ${arqn} to netcdf with success, and reduced size. " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
     fi

     # NFCENS
     arqn=$DIR/gwes.$ANO$MES$DIA$HORA/nfcens$e.t${HORA}z
     test -f ${arqn}.grib2 >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA 2>&1
     TE=$?
     if [ ${TE} -eq 1 ]; then
       echo " File ${arqn}.grib2 does not exist. Failed to download " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
     else
       /usr/local/grib2/wgrib2/wgrib2 ${arqn}.grib2 -netcdf ${arqn}.saux.nc
       /usr/bin/cdo sellonlatbox,-180,180,-90,90 ${arqn}.saux.nc ${arqn}.saux1.nc
       /usr/bin/ncks -4 -L 1 -d latitude,${latmin},${latmax} ${arqn}.saux1.nc ${arqn}.saux2.nc
       /usr/bin/ncks -4 -L 1 -d longitude,${lonmin},${lonmax} ${arqn}.saux2.nc ${arqn}.saux3.nc
       /usr/bin/ncatted -a _FillValue,,o,f,NaN ${arqn}.saux3.nc
       /usr/bin/ncks --ppc default=.$dp ${arqn}.saux3.nc $DIR/gwes.$ANO$MES$DIA$HORA/nfcens$e.glo_30m.$ANO$MES$DIA$HORA.nc
       rm -f ${arqn}.grib2
       rm ${arqn}.saux*
       echo " Converted file ${arqn} to netcdf with success, and reduced size. " >> $DIR/gwes.$ANO$MES$DIA$HORA/logGWES_$ANO$MES$DIA$HORA
     fi

done

# permissions and groups
# chgrp amadmin -R $DIR/gwes.$ANO$MES$DIA$HORA
chmod -R 775 $DIR/gwes.$ANO$MES$DIA$HORA



