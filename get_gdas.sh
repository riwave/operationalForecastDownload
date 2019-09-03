#!/bin/bash

################################################################
#
#     Script to fetch NOAA/GDAS via CURL,
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

# number of days before
mdb=4
# limits for domain selection
latmin=-77.5
latmax=90.
lonmin=-102.
lonmax=30.
# List of variables in the .idx file
UGRD=":UGRD:850 mb:|:UGRD:10 m above ground:"
VGRD=":VGRD:850 mb:|:VGRD:10 m above ground:"
GUST=":GUST:surface:"
HGT=":HGT:850 mb:"
ICE=":ICEC:surface:"
RH=":RH:2 m above ground:"
TMP=":TMP:2 m above ground:"
PRMSL=":PRMSL:mean sea level:"
VARSGET="$UGRD|$VGRD|$GUST|$HGT|$ICE|$RH|$TMP|$PRMSL"
# float array resolution (number of decimals)
dp=2
# GDAS resolution
res=25
# server address
SERVER=https://www.ftp.ncep.noaa.gov

# initial date for the ftp and directory
ANO=`date +%Y`
MES=`date +%m`
DIA=`date +%d`
HORA=00

cd $DIR
# create directory
mkdir -p $DIR/gdas.$ANO$MES$DIA
# all information about fetching the grib2 files will be saved in the log file 
echo "  " > $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA

# GDAS download for the last mdb days
# loop last l days
ldmy="`seq -f "%03g" $mdb -1 1`"
cycle="`seq -f "%02g" 0 6 18`"

for l in $ldmy;do
  PANO=`date --date=-$l' day' '+%Y'`
  PMES=`date --date=-$l' day' '+%m'`
  PDIA=`date --date=-$l' day' '+%d'`
  # loop cycle
  for cl in $cycle;do

    if [ ${cl} -eq "18" ] && [ ${l} -eq "001" ];then
      hours="`seq -f "%03g" 0 1 6`"
    else
      hours="`seq -f "%03g" 0 1 5`"
    fi

    # loop "forecast" hours
    for h in $hours;do

      echo "  " >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
      echo " ======== GDAS hindcast: $ANO$MES$DIA |   $PANO$PMES$PDIA cycle "$cl" hour "$h" ========" >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
      # size TAM and tries TRIES will control the process
      TAM=0
      TRIES=1
      # while file has a lower size the expected or attemps are less than 130 (almos 11 hours trying) it does:
      while [ ${TAM} -lt 5000000  ] && [ ${TRIES} -le 130 ]; do
        # sleep 5 minutes between attemps
        if [ ${TRIES} -gt 5 ]; then
          sleep 300
        fi
        # --- CURL VIA WWW.FTP.NCEP.NOAA.GOV --- #
        if [ ${TAM} -lt 5000000 ]; then
            echo "  " >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
            echo " attempt number: $TRIES" >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
            echo "  " >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
            # main line where get_inv.pl and get_grib.pl are used to fech the grib2 file
            $DIRS/get_inv.pl $SERVER/data/nccf/com/gfs/prod/gdas.${PANO}${PMES}${PDIA}/${cl}/gdas.t${cl}z.pgrb2.0p${res}.f${h}.idx | egrep "($VARSGET)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/gfs/prod/gdas.${PANO}${PMES}${PDIA}/${cl}/gdas.t${cl}z.pgrb2.0p${res}.f${h} $DIR/gdas.$ANO$MES$DIA/gdas.${PANO}${PMES}${PDIA}.t${cl}z.pgrb2.0p${res}.f${h}.grb2 >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA 2>&1         
            # test if the downloaded file exists
            test -f $DIR/gdas.$ANO$MES$DIA/gdas.${PANO}${PMES}${PDIA}.t${cl}z.pgrb2.0p${res}.f${h}.grb2 >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA 2>&1
            TE=$?
            if [ "$TE" -eq 1 ]; then
              TAM=0
            else
              # check size of each file
              TAM=`du -sb $DIR/gdas.$ANO$MES$DIA/gdas.${PANO}${PMES}${PDIA}.t${cl}z.pgrb2.0p${res}.f${h}.grb2 | awk '{ print $1 }'` >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA 2>&1
            fi
        fi

        TRIES=`expr $TRIES + 1`
      done
    done
  done
done

# Check the entire download, as a whole, inside the directory
TAMD=`du -sb $DIR/gdas.$ANO$MES$DIA | awk '{ print $1}'` >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA 2>&1
TAMDW=`du -sh $DIR/gdas.$ANO$MES$DIA | awk '{ print $1}'` >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA 2>&1
echo " " >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
echo " " >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
echo "---- Final Status ----" >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
NANO=`date '+%Y'`
NMES=`date '+%m'`
NDIA=`date '+%d'`
NHORA=`date '+%H'`
NMINUTO=`date '+%M'`
if [ ${TAMD} -gt 500000000 ]; then
  echo " Entire Download successfully completed, no  problem found. Total size: $TAMDW" >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA  
  echo " Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO" >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
else
  echo " ATTENTION! Some error has happened during the download. Total size: $TAMDW" >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
  echo " Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO" >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA 
  # Send e-mail in case of problems,  see /media/rmc/bento/Library/Manuals_Tips/enviandoemail
cat > email.txt << EOF
To: $emaildest
Subject: GDAS Download Problem

ATTENTION! Some error has happened during GDAS download. Total size: $TAMDW
In: $DIR/gdas.$ANO$MES$DIA
Script: $DIRS/get_gdas.sh
Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO
EOF
  /usr/sbin/ssmtp $emaildest -au$emailfonte -ap$senha < email.txt >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA 2>&1	
  rm -f email*	
fi
echo "----------------------" >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA


# Cleaning, Remove directories older than 5 days
cd $DIR
# find gdas.???????? -ctime +4 -type d | xargs rm -rf >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA 2>&1 

# Post-processing: select area and reduces resolution, in order to save disk space. ------------------
echo " " >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
echo " Post-Processing. select area and reduces resolution " >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA

for l in $ldmy;do
  PANO=`date --date=-$l' day' '+%Y'`
  PMES=`date --date=-$l' day' '+%m'`
  PDIA=`date --date=-$l' day' '+%d'`
  # loop cycle
  for cl in $cycle;do

    if [ ${cl} -eq "18" ] && [ "$l" -eq "001" ];then
      hours="`seq -f "%03g" 0 1 6`"
    else
      hours="`seq -f "%03g" 0 1 5`"
    fi

    # loop "forecast" hours
    for h in $hours;do

      arqn=$DIR/gdas.$ANO$MES$DIA/gdas.${PANO}${PMES}${PDIA}.t${cl}z.pgrb2.0p${res}.f${h}

      test -f ${arqn}.grb2 >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA 2>&1
      TE=$?
      if [ "$TE" -eq 1 ]; then
        echo " File ${arqn}.grb2 does not exist. Failed to download " >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA
      else

        /usr/local/grib2/wgrib2/wgrib2 ${arqn}.grb2 -netcdf ${arqn}.saux.nc
        /usr/bin/cdo sellonlatbox,-180,180,-90,90 ${arqn}.saux.nc ${arqn}.saux1.nc
        /usr/bin/ncks -4 -L 1 -d latitude,${latmin},${latmax} ${arqn}.saux1.nc ${arqn}.saux2.nc
        /usr/bin/ncks -4 -L 1 -d longitude,${lonmin},${lonmax} ${arqn}.saux2.nc ${arqn}.saux3.nc
        /usr/bin/ncatted -a _FillValue,,o,f,NaN ${arqn}.saux3.nc
        /usr/bin/ncks --ppc default=.$dp ${arqn}.saux3.nc ${arqn}.nc
        rm -f ${arqn}.grb2
        rm ${arqn}.saux*
        echo " Converted file ${arqn} to netcdf with success, and reduced size. " >> $DIR/gdas.$ANO$MES$DIA/logGDAS_$ANO$MES$DIA

      fi
    done
  done
done

PANOf=`date --date=-1' day' '+%Y'`
PMESf=`date --date=-1' day' '+%m'`
PDIAf=`date --date=-1' day' '+%d'`
cl=18
h=006
mv $DIR/gdas.$ANO$MES$DIA/gdas.${PANOf}${PMESf}${PDIAf}.t${cl}z.pgrb2.0p${res}.f${h}.nc $DIR/gdas.$ANO$MES$DIA/gdas.$ANO$MES$DIA.nowcast.pgrb2.0p${res}.nc

# Merge all netcdf files
/usr/bin/ncecat $DIR/gdas.$ANO$MES$DIA/*.f* -O $DIR/gdas.$ANO$MES$DIA/gdas.$ANO$MES$DIA.last${mdb}days.pgrb2.0p${res}.nc
rm -f $DIR/gdas.$ANO$MES$DIA/*.f*

# permissions and groups
# chgrp amadmin -R $DIR/gdas.$ANO$MES$DIA
chmod -R 775 $DIR/gdas.$ANO$MES$DIA

