#!/bin/bash
# Product generation script for hdwx-modelplotter
# Created 15 September 2021 by Sam Gardner <stgardner4@tamu.edu>

if [ ! -d output/ ]
then
    mkdir output/
fi

if [ -f status.txt ]
then
  echo "lockfile found, exiting"
  exit
fi
touch status.txt

models=("hrrr" "nam" "gfs" "namnest")
for model in "${models[@]}"
do
    if [ -f plotcmds.txt ]
    then
        rm plotcmds.txt
    fi
    echo "Fetch $model" >> status.txt
    if [ -f ~/mambaforge/envs/HDWX/bin/python3 ]
    then
        ~/mambaforge/envs/HDWX/bin/python3 modelFetch.py $model
    fi
    if [ -f ~/miniconda3/envs/HDWX/bin/python3 ]
    then
        ~/miniconda3/envs/HDWX/bin/python3 modelFetch.py $model
    fi
    if [ -f plotcmds.txt ]
    then
        plotcmdStr=`cat plotcmds.txt`
        IFS=$'\n' plotcmdArr=($plotcmdStr)
        counter=0
        echo "Plot $model" >> status.txt
        for plotcmd in "${plotcmdArr[@]}"
        do
            eval "$plotcmd" &
            procpids[${counter}]=$!
            ((counter=counter+1))
            while [ ${#procpids[@]} == 4 ]
            do
                for procpid in ${procpids[*]}
                do
                    if ! kill -0 $procpid 2>/dev/null
                    then 
                        procpids=(${procpids[@]/$procpid})
                    fi
                done
            done
        done
        for procpid in ${procpids[*]}
        do
            wait $procpid
        done
    fi
done

rm status.txt
