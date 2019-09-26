#!/bin/bash

################################################################
#
#     Script to fetch Global Ensemble forecasts via CURL and WGET- cycle 00Z
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

s1="pgrb2a"
s2="pgrb2b"

# limits for domain selection
latmin=-77.5
latmax=90.
lonmin=-102.
lonmax=30.
# Global Ensemble Forecast System (GEFS) https://www.ncdc.noaa.gov/data-access/model-data/model-datasets/global-ensemble-forecast-system-gefs
# https://www.ftp.ncep.noaa.gov/data/nccf/com/gens/prod/gefs.20160803/00/pgrb2/
# gep20.t00z.pgrb2f354.idx 
UGRD=":UGRD:850 mb:|:UGRD:10 m above ground:"
VGRD=":VGRD:850 mb:|:VGRD:10 m above ground:"
GUST=":GUST:surface:"
PRMSL=":PRMSL:mean sea level:"
HGT=":HGT:850 mb:"
VARSGETGEFS1="$UGRD|$VGRD|$PRMSL|$HGT"
VARSGETGEFS2="$GUST"

# Canadian Meteorological Center Ensemble (CMCE) http://nomads.ncep.noaa.gov/txt_descriptions/CMCENS_doc.shtml
# Fleet Numerical Meteorology and Ocenography Ensemble Forecast System (FENS) http://www.nco.ncep.noaa.gov/pmb/products/fens/
# https://www.ftp.ncep.noaa.gov/data/nccf/com/naefs/prod/
VARSGETNAEFS="$UGRD|$VGRD|$PRMSL|$HGT"

# initial date cycle for the ftp
ANO=`date +%Y`
MES=`date +%m`
DIA=`date +%d`
# pa=1
# ANO=`date --date=-$pa' day' '+%Y'`
# MES=`date --date=-$pa' day' '+%m'`
# DIA=`date --date=-$pa' day' '+%d'`
HORA="00" # first cycle 00Z

cd $DIR
# create directory
mkdir -p $DIR/gens.$ANO$MES$DIA$HORA
# all information about fetching the grib2 files will be saved in the log file 
echo "  " > $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA

# hours of forecast to be dowloaded
horas=`seq -f "%02g" 0 6 384`
# number of ensembles
ensbl="`seq -f "%02g" 0 1 20`"
ensblf="`seq -f "%02g" 1 1 20`"

for h in $horas;do
  for e in $ensbl;do
    # GENS GEFS (1X1, 6h) --------------------------------------------------
    echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
    echo " ======== GENS GEFS Forecast: $ANO$MES$DIA$HORA  $h ========" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 

    # size TAM and tries TRIES will control the process
    TAM=0
    TRIES=1
    # while file has a lower size the expected or attemps are less than 130 (almos 11 hours trying) it does:
    while [ $TAM -lt 800000 ] && [ $TRIES -le 130 ]; do
      # sleep 5 minutes between attemps
      if [ ${TRIES} -gt 5 ]; then
        sleep 300
      fi
      # --- CURL VIA WWW.FTP.NCEP.NOAA.GOV --- #
      if [ ${TAM} -lt 800000 ]; then
          echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          echo " attempt number: $TRIES" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          # main line where get_inv.pl and get_grib.pl are used to fech the grib2 file  
          if [ ${e} == 00 ]; then
             $DIRS/get_inv.pl $SERVER/data/nccf/com/gens/prod/gefs.$ANO$MES$DIA/$HORA/${s1}p5/gec${e}.t${HORA}z.${s1}.0p50.f"$(printf "%03d" $h)".idx | egrep "($VARSGETGEFS1)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/gens/prod/gefs.$ANO$MES$DIA/$HORA/${s1}p5/gec${e}.t${HORA}z.${s1}.0p50.f"$(printf "%03d" $h)" $DIR/gens.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1         
          else
             $DIRS/get_inv.pl $SERVER/data/nccf/com/gens/prod/gefs.$ANO$MES$DIA/$HORA/${s1}p5/gep${e}.t${HORA}z.${s1}.0p50.f"$(printf "%03d" $h)".idx | egrep "($VARSGETGEFS1)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/gens/prod/gefs.$ANO$MES$DIA/$HORA/${s1}p5/gep${e}.t${HORA}z.${s1}.0p50.f"$(printf "%03d" $h)" $DIR/gens.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1         
          fi
          # test if the downloaded file exists
          test -f $DIR/gens.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
          TE=$?
          if [ ${TE} -eq 1 ]; then
            TAM=0
          else
            # check size of each file
            TAM=`du -sb $DIR/gens.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 | awk '{ print $1 }'` >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
          fi
      fi

      TRIES=`expr $TRIES + 1`
    done
    sleep 2

    # size TAM and tries TRIES will control the process
    TAM=0
    TRIES=1
    # while file has a lower size the expected or attemps are less than 130 (almos 11 hours trying) it does:
    while [ $TAM -lt 100000 ] && [ $TRIES -le 130 ]; do
      # sleep 5 minutes between attemps
      if [ ${TRIES} -gt 5 ]; then
        sleep 300
      fi
      # --- CURL VIA WWW.FTP.NCEP.NOAA.GOV --- #
      if [ ${TAM} -lt 100000 ]; then
          echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          echo " attempt number: $TRIES" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          # main line where get_inv.pl and get_grib.pl are used to fech the grib2 file  
          if [ ${e} == 00 ]; then
             $DIRS/get_inv.pl $SERVER/data/nccf/com/gens/prod/gefs.$ANO$MES$DIA/$HORA/${s2}p5/gec${e}.t${HORA}z.${s2}.0p50.f"$(printf "%03d" $h)".idx | egrep "($VARSGETGEFS2)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/gens/prod/gefs.$ANO$MES$DIA/$HORA/${s2}p5/gec${e}.t${HORA}z.${s2}.0p50.f"$(printf "%03d" $h)" $DIR/gens.$ANO$MES$DIA$HORA/gefs_gust${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1         
          else
             $DIRS/get_inv.pl $SERVER/data/nccf/com/gens/prod/gefs.$ANO$MES$DIA/$HORA/${s2}p5/gep${e}.t${HORA}z.${s2}.0p50.f"$(printf "%03d" $h)".idx | egrep "($VARSGETGEFS2)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/gens/prod/gefs.$ANO$MES$DIA/$HORA/${s2}p5/gep${e}.t${HORA}z.${s2}.0p50.f"$(printf "%03d" $h)" $DIR/gens.$ANO$MES$DIA$HORA/gefs_gust${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1         
          fi
          # test if the downloaded file exists
          test -f $DIR/gens.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
          TE=$?
          if [ ${TE} -eq 1 ]; then
            TAM=0
          else
            # check size of each file
            TAM=`du -sb $DIR/gens.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 | awk '{ print $1 }'` >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
          fi
      fi

      TRIES=`expr $TRIES + 1`
    done
    sleep 2

  done
  sleep 5
done
sleep 30

for h in $horas;do
  for e in $ensbl;do
    # GENS CMCE (1X1, 6h) --------------------------------------------------
    echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
    echo " ======== GENS CMCE Forecast: $ANO$MES$DIA$HORA  $h ========" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 
    # size TAM and tries TRIES will control the process
    TAM=0
    TRIES=1
    # while file has a lower size the expected or attemps are less than 130 (almos 11 hours trying) it does:
    while [ $TAM -lt 700000 ] && [ $TRIES -le 130 ]; do
      # sleep 5 minutes between attemps
      if [ ${TRIES} -gt 5 ]; then
        sleep 300
      fi
      # --- CURL VIA WWW.FTP.NCEP.NOAA.GOV --- #
      if [ ${TAM} -lt 700000 ]; then
          echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          echo " attempt number: $TRIES" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          # main line where get_inv.pl and get_grib.pl are used to fech the grib2 file 
          if [ ${e} == 00 ]; then
             $DIRS/get_inv.pl $SERVER/data/nccf/com/naefs/prod/cmce.$ANO$MES$DIA/$HORA/pgrb2ap5/cmc_gec"$e".t"$HORA"z.pgrb2a.0p50.f"$(printf "%03d" $h)".idx | egrep "($VARSGETNAEFS)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/naefs/prod/cmce.$ANO$MES$DIA/$HORA/pgrb2ap5/cmc_gec${e}.t${HORA}z.pgrb2a.0p50.f"$(printf "%03d" $h)" $DIR/gens.$ANO$MES$DIA$HORA/cmce${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1         
          else
             $DIRS/get_inv.pl $SERVER/data/nccf/com/naefs/prod/cmce.$ANO$MES$DIA/$HORA/pgrb2ap5/cmc_gep"$e".t"$HORA"z.pgrb2a.0p50.f"$(printf "%03d" $h)".idx | egrep "($VARSGETNAEFS)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/naefs/prod/cmce.$ANO$MES$DIA/$HORA/pgrb2ap5/cmc_gep${e}.t${HORA}z.pgrb2a.0p50.f"$(printf "%03d" $h)" $DIR/gens.$ANO$MES$DIA$HORA/cmce${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1         
          fi
          # test if the downloaded file exists
          test -f $DIR/gens.$ANO$MES$DIA$HORA/cmce${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
          TE=$?
          if [ ${TE} -eq 1 ]; then
            TAM=0
          else
            # check size of each file
            TAM=`du -sb $DIR/gens.$ANO$MES$DIA$HORA/cmce${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 | awk '{ print $1 }'` >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
          fi
      fi

      TRIES=`expr $TRIES + 1`
    done
    sleep 2
  done
  sleep 5
done
sleep 30

for h in $horas;do
  for e in $ensblf;do
    # GENS FENS (1X1, 6h) --------------------------------------------------
    echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
    echo " ======== GENS FENS Forecast: $ANO$MES$DIA$HORA  $h ========" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
    # size TAM and tries TRIES will control the process
    TAM=0
    TRIES=1
    # while file has a lower size the expected or attemps are less than 130 (almos 11 hours trying) it does:
    # 3000000
    while [ $TAM -lt 800000 ] && [ $TRIES -le 130 ]; do
      # sleep 5 minutes between attemps
      if [ ${TRIES} -gt 5 ]; then
        sleep 300
      fi
      # --- CURL VIA WWW.FTP.NCEP.NOAA.GOV --- #
      if [ ${TAM} -lt 800000 ]; then
          echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          echo " attempt number: $TRIES" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          echo "  " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
          $DIRS/get_inv.pl $SERVER/data/nccf/com/naefs/prod/fens.$ANO$MES$DIA/$HORA/pgrb2ap5/ENSEMBLE.halfDegree.MET.fcst_et0$e."$(printf "%03d" $h)".$ANO$MES$DIA$HORA.idx | egrep "($VARSGETNAEFS)" | $DIRS/get_grib.pl $SERVER/data/nccf/com/naefs/prod/fens.$ANO$MES$DIA/$HORA/pgrb2ap5/ENSEMBLE.halfDegree.MET.fcst_et0${e}."$(printf "%03d" $h)".$ANO$MES$DIA$HORA $DIR/gens.$ANO$MES$DIA$HORA/fens${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1         
          sleep 2
          # test if the downloaded file exists
          test -f $DIR/gens.$ANO$MES$DIA$HORA/fens${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
          TE=$?
          if [ ${TE} -eq 1 ]; then
            TAM=0
          else
            # check size of each file
            TAM=`du -sb $DIR/gens.$ANO$MES$DIA$HORA/fens${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)".grb2 | awk '{ print $1 }'` >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
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
TAMD=`du -sb $DIR/gens.$ANO$MES$DIA$HORA | awk '{ print $1}'` >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
TAMDW=`du -sh $DIR/gens.$ANO$MES$DIA$HORA | awk '{ print $1}'` >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
echo " " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
echo " " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
echo "---- Final Status ----" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
NANO=`date '+%Y'`
NMES=`date '+%m'`
NDIA=`date '+%d'`
NHORA=`date '+%H'`
NMINUTO=`date '+%M'`
if [ ${TAMD} -gt 4000000000 ]; then
  echo " Entire Download successfully completed, no  problem found. Total size: $TAMDW" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA  
  echo " Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
else
  echo " ATTENTION! Some error has happened during the download. Total size: $TAMDW" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
  echo " Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 
  # Send e-mail in case of problems,  see /media/rmc/bento/Library/Manuals_Tips/enviandoemail
cat > email.txt << EOF
To: $emaildest
Subject: GENS Download Problem

ATTENTION! Some error has happened during the GENS download. Total size: $TAMDW
In: $DIR/gens.$ANO$MES$DIA$HORA
Script: $DIRS/get_gens_c00.sh
Local Time: $NANO $NMES $NDIA - $NHORA:$NMINUTO
EOF
  /usr/sbin/ssmtp $emaildest -au$emailfonte -ap$senha < email.txt >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1	
  rm -f email*	
fi
echo "----------------------" >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA


# Cleaning 
# --- Remove directories older than 5 days
cd $DIR
# find gens.?????????? -ctime +4 -type d | xargs rm -rf >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1 

# Post-processing: select area and reduces resolution, in order to save disk space. ------------------
echo " " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
echo " Post-Processing. select area and reduces resolution " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA

for h in $horas;do
  for e in $ensbl;do

     # GEFS
     arqn=$DIR/gens.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)"
     test -f ${arqn}.grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
     TE=$?
     if [ ${TE} -eq 1 ]; then
       echo " File ${arqn}.grb2 does not exist. Failed to download " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
     else
       /usr/local/grib2/wgrib2/wgrib2 ${arqn}.grb2 -netcdf ${arqn}.saux.nc
       /usr/bin/cdo sellonlatbox,-180,180,-90,90 ${arqn}.saux.nc ${arqn}.saux1.nc
       /usr/bin/ncks -4 -L 1 -d latitude,${latmin},${latmax} ${arqn}.saux1.nc ${arqn}.saux2.nc
       /usr/bin/ncks -4 -L 1 -d longitude,${lonmin},${lonmax} ${arqn}.saux2.nc ${arqn}.saux3.nc
       /usr/bin/ncatted -a _FillValue,,o,f,NaN ${arqn}.saux3.nc
       /usr/bin/ncks --ppc default=.$dp ${arqn}.saux3.nc ${arqn}.nc
       rm -f ${arqn}.grb2
       rm ${arqn}.saux*
       echo " Converted file ${arqn} to netcdf with success, and reduced size. " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
     fi

     # CMCE
     arqn=$DIR/gens.$ANO$MES$DIA$HORA/cmce${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)"
     test -f ${arqn}.grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
     TE=$?
     if [ ${TE} -eq 1 ]; then
       echo " File ${arqn}.grb2 does not exist. Failed to download " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
     else
       /usr/local/grib2/wgrib2/wgrib2 ${arqn}.grb2 -netcdf ${arqn}.saux.nc
       /usr/bin/cdo sellonlatbox,-180,180,-90,90 ${arqn}.saux.nc ${arqn}.saux1.nc
       /usr/bin/ncks -4 -L 1 -d latitude,${latmin},${latmax} ${arqn}.saux1.nc ${arqn}.saux2.nc
       /usr/bin/ncks -4 -L 1 -d longitude,${lonmin},${lonmax} ${arqn}.saux2.nc ${arqn}.saux3.nc
       /usr/bin/ncatted -a _FillValue,,o,f,NaN ${arqn}.saux3.nc
       /usr/bin/ncks --ppc default=.$dp ${arqn}.saux3.nc ${arqn}.nc
       rm -f ${arqn}.grb2
       rm ${arqn}.saux*
       echo " Converted file ${arqn} to netcdf with success, and reduced size. " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
     fi

     # FENS
     if [ ${e} -gt 0 ]; then
       arqn=$DIR/gens.$ANO$MES$DIA$HORA/fens${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)"
       test -f ${arqn}.grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
       TE=$?
       if [ ${TE} -eq 1 ]; then
         echo " File ${arqn}.grb2 does not exist. Failed to download " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
       else
         /usr/local/grib2/wgrib2/wgrib2 ${arqn}.grb2 -netcdf ${arqn}.saux.nc
         /usr/bin/cdo sellonlatbox,-180,180,-90,90 ${arqn}.saux.nc ${arqn}.saux1.nc
         /usr/bin/ncks -4 -L 1 -d latitude,${latmin},${latmax} ${arqn}.saux1.nc ${arqn}.saux2.nc
         /usr/bin/ncks -4 -L 1 -d longitude,${lonmin},${lonmax} ${arqn}.saux2.nc ${arqn}.saux3.nc
         /usr/bin/ncatted -a _FillValue,,o,f,NaN ${arqn}.saux3.nc
         /usr/bin/ncks --ppc default=.$dp ${arqn}.saux3.nc ${arqn}.nc
         rm -f ${arqn}.grb2
         rm ${arqn}.saux*
         echo " Converted file ${arqn} to netcdf with success, and reduced size. " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
       fi
     fi

     # GEFS Gust only
     arqn=$DIR/gens.$ANO$MES$DIA$HORA/gefs_gust${e}.t${HORA}z.pgrb2f"$(printf "%03d" $h)"
     test -f ${arqn}.grb2 >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA 2>&1
     TE=$?
     if [ ${TE} -eq 1 ]; then
       echo " File ${arqn}.grb2 does not exist. Failed to download " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
     else
       /usr/local/grib2/wgrib2/wgrib2 ${arqn}.grb2 -netcdf ${arqn}.saux.nc
       /usr/bin/cdo sellonlatbox,-180,180,-90,90 ${arqn}.saux.nc ${arqn}.saux1.nc
       /usr/bin/ncks -4 -L 1 -d latitude,${latmin},${latmax} ${arqn}.saux1.nc ${arqn}.saux2.nc
       /usr/bin/ncks -4 -L 1 -d longitude,${lonmin},${lonmax} ${arqn}.saux2.nc ${arqn}.saux3.nc
       /usr/bin/ncatted -a _FillValue,,o,f,NaN ${arqn}.saux3.nc
       /usr/bin/ncks --ppc default=.$dp ${arqn}.saux3.nc ${arqn}.nc
       rm -f ${arqn}.grb2
       rm ${arqn}.saux*
       echo " Converted file ${arqn} to netcdf with success, and reduced size. " >> $DIR/gens.$ANO$MES$DIA$HORA/logGENS_$ANO$MES$DIA$HORA
     fi

  done
done


# Merge all netcdf files
for e in $ensbl;do
  /usr/bin/ncecat $DIR/gens.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2f*.nc -O $DIR/gens.$ANO$MES$DIA$HORA/gefs.$ANO$MES$DIA$HORA.m${e}.${s1}p5.nc
  /usr/bin/ncecat $DIR/gens.$ANO$MES$DIA$HORA/cmce${e}.t${HORA}z.pgrb2f*.nc -O $DIR/gens.$ANO$MES$DIA$HORA/cmce.$ANO$MES$DIA$HORA.m${e}.pgrb2ap5.nc
  /usr/bin/ncecat $DIR/gens.$ANO$MES$DIA$HORA/fens${e}.t${HORA}z.pgrb2f*.nc -O $DIR/gens.$ANO$MES$DIA$HORA/fens.$ANO$MES$DIA$HORA.m${e}.pgrb2ap5.nc
  rm -f $DIR/gens.$ANO$MES$DIA$HORA/gefs${e}.t${HORA}z.pgrb2f*.nc
  rm -f $DIR/gens.$ANO$MES$DIA$HORA/cmce${e}.t${HORA}z.pgrb2f*.nc
  rm -f $DIR/gens.$ANO$MES$DIA$HORA/fens${e}.t${HORA}z.pgrb2f*.nc
done
for e in $ensbl;do
  /usr/bin/ncecat $DIR/gens.$ANO$MES$DIA$HORA/gefs_gust${e}.t${HORA}z.pgrb2f*.nc -O $DIR/gens.$ANO$MES$DIA$HORA/gefs_gust.$ANO$MES$DIA$HORA.m${e}.${s2}p5.nc
  rm -f $DIR/gens.$ANO$MES$DIA$HORA/gefs_gust${e}.t${HORA}z.pgrb2f*.nc
done


# permissions and groups
# chgrp amadmin -R $DIR/gfs.$ANO$MES$DIA$HORA
chmod -R 775 $DIR/gens.$ANO$MES$DIA$HORA

