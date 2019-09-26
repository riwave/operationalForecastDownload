#!/bin/bash

################################################################
#
#     Script to fetch NOAA/GFS forecast via CURL - cycle 00Z
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
# List of variables in the .idx file. Surface, higher resolution
# Surface, higher resolution
TMP=":TMP:2 m above ground:"
UGRDS=":UGRD:10 m above ground:"
VGRDS=":VGRD:10 m above ground:"
VARSGET="$UGRDS|$VGRDS|$TMP"

# float array resolution (number of decimals)
dp=2

# initial date cycle for the ftp
ANO=`date +%Y`
MES=`date +%m`
DIA=`date +%d`
HORA="00" # first cycle 00Z
# get previous forecast cycles (-1 in this case)
# ANO=`date --date=-1' day' '+%Y'`
# MES=`date --date=-1' day' '+%m'`
# DIA=`date --date=-1' day' '+%d'`

cd $DIR
# create directory
mkdir -p $DIR/gfs.surface.$ANO$MES$DIA$HORA
# all information about fetching the grib2 files will be saved in the log file 
echo "  " > $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA

# hours of forecast to be dowloaded
h1="`seq -f "%03g" 0 1 120`"
h2="`seq -f "%03g" 123 3 384`"
horas=${h1}' '${h2}
#
for h in $horas;do
  echo "  " >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
  echo " ======== GFS Forecast Surface: $ANO$MES$DIA$HORA  $h ========" >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA 
  # size TAM and tries TRIES will control the process
  TAM=0
  TRIES=1
  # while file has a lower size the expected or attemps are less than 130 (almos 11 hours trying) it does:
  while [ ${TAM} -lt 5000000 ] && [ ${TRIES} -le 130 ]; do
    # sleep 5 minutes between attemps
    if [ ${TRIES} -gt 5 ]; then
      sleep 300
    fi
    # --- CURL VIA WWW.FTP.NCEP.NOAA.GOV --- #
    if [ ${TAM} -lt 5000000 ]; then
        echo "  " >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
        echo " attempt number: $TRIES" >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
        echo "  " >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
        # main line where get_inv.pl and get_grib.pl are used to fech the grib2 file
        $DIRS/get_inv.pl $SERVER/data/nccf/com/gfs/prod/gfs.$ANO$MES$DIA/${HORA}/gfs.t${HORA}z.sfluxgrbf$h.grib2.idx | egrep "($VARSGET)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/gfs/prod/gfs.$ANO$MES$DIA/${HORA}/gfs.t${HORA}z.sfluxgrbf$h.grib2 $DIR/gfs.surface.$ANO$MES$DIA$HORA/gfs.surface.t${HORA}z.sfluxgrbf$h.grib2 >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA 2>&1      
        # test if the downloaded file exists
        test -f $DIR/gfs.surface.$ANO$MES$DIA$HORA/gfs.surface.t${HORA}z.sfluxgrbf$h.grib2 >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA 2>&1
        TE=$?
        if [ "$TE" -eq 1 ]; then
          TAM=0
        else
          # check size of each file
          TAM=`du -sb $DIR/gfs.surface.$ANO$MES$DIA$HORA/gfs.surface.t${HORA}z.sfluxgrbf$h.grib2 | awk '{ print $1 }'` >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA 2>&1
        fi
    fi

    TRIES=`expr $TRIES + 1`
  done
done

# Check the entire download, as a whole, inside the directory
TAMD=`du -sb $DIR/gfs.surface.$ANO$MES$DIA$HORA | awk '{ print $1}'` >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA 2>&1
TAMDW=`du -sh $DIR/gfs.surface.$ANO$MES$DIA$HORA | awk '{ print $1}'` >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA 2>&1
echo " " >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
echo " " >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
echo "---- Final Status ----" >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
NANO=`date '+%Y'`
NMES=`date '+%m'`
NDIA=`date '+%d'`
NHORA=`date '+%H'`
NMINUTO=`date '+%M'`
if [ ${TAMD} -gt 1200000000 ]; then
  echo " Entire Download successfully completed, no  problem found. Total size: $TAMDW" >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA  
  echo " Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO" >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
else
  echo " ATTENTION! Some error has happened during the download. Total size: $TAMDW" >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
  echo " Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO" >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA 
  # Send e-mail in case of problems,  see /media/rmc/bento/Library/Manuals_Tips/enviandoemail
cat > email.txt << EOF
To: $emaildest
Subject: GFS Surface Download Problem

ATTENTION! Some error has happened during the GFS download. Total size: $TAMDW
In: $DIR/gfs.surface.$ANO$MES$DIA$HORA
Script: $DIRS/get_gfs_c00.sh
Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO
EOF
  /usr/sbin/ssmtp $emaildest -au$emailfonte -ap$senha < email.txt >> $DIR/gfs.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA 2>&1	
  rm -f email*
fi
echo "----------------------" >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA


# Cleaning 
# --- Remove directories older than 5 days
cd $DIR
# find gfs.?????????? -ctime +4 -type d | xargs rm -rf >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA 2>&1 

# Post-processing: select area and reduces resolution, in order to save disk space. ------------------
echo " " >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
echo " Post-Processing. select area and reduces resolution " >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA

for h in $horas;do

   arqn=$DIR/gfs.surface.$ANO$MES$DIA$HORA/gfs.surface.t${HORA}z.sfluxgrbf$h

   test -f ${arqn}.grib2 >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA 2>&1
   TE=$?
   if [ ${TE} -eq 1 ]; then
     echo " File ${arqn}.grib2 does not exist. Failed to download " >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA
   else

     /usr/local/grib2/wgrib2/wgrib2 ${arqn}.grib2 -netcdf ${arqn}.saux.nc
     /usr/bin/cdo sellonlatbox,-180,180,-90,90 ${arqn}.saux.nc ${arqn}.saux1.nc
     /usr/bin/ncks -4 -L 1 -d latitude,${latmin},${latmax} ${arqn}.saux1.nc ${arqn}.saux2.nc
     /usr/bin/ncks -4 -L 1 -d longitude,${lonmin},${lonmax} ${arqn}.saux2.nc ${arqn}.saux3.nc
     /usr/bin/ncatted -a _FillValue,,o,f,NaN ${arqn}.saux3.nc
     /usr/bin/ncks --ppc default=.$dp ${arqn}.saux3.nc ${arqn}.nc
     rm -f ${arqn}.grib2
     rm ${arqn}.saux*

     echo " Converted file ${arqn} to netcdf with success, and reduced size. " >> $DIR/gfs.surface.$ANO$MES$DIA$HORA/logGFS_$ANO$MES$DIA$HORA

   fi
done

# Merge all netcdf files
/usr/bin/ncecat $DIR/gfs.surface.$ANO$MES$DIA$HORA/*.nc -O $DIR/gfs.surface.$ANO$MES$DIA$HORA/gfs.surface.$ANO$MES$DIA$HORA.sflux.nc
rm -f $DIR/gfs.surface.$ANO$MES$DIA$HORA/*.sfluxgrbf*

# permissions and groups
# chgrp amadmin -R $DIR/gfs.surface.$ANO$MES$DIA$HORA
chmod -R 775 $DIR/gfs.surface.$ANO$MES$DIA$HORA


