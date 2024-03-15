#!/bin/bash

Temp="1.00 1.20 1.40 1.60 1.80 2.00 2.20 2.40 2.60 2.80 3.00 3.20 3.40 3.60 3.80 4.00 4.20 4.40 4.60 4.80 5.00"
# Temp="0.40 1.00 1.20 1.40 1.60 1.80 2.00 2.20 2.40 2.60 2.80 3.00 3.20 3.40 3.60 3.80 4.00 4.20 4.40 4.60 4.80 5.00 6.00 7.00 8.00 9.00 10.00"
Temp="2.60 3.00 3.40 3.80 4.20 4.60"

H=$(sed -n '10p' input.txt)

jobfile="job1.sh"

for j in $Temp
do
    echo "T = $j, H = $H"

    # change the input.txt file line 7 to the current temperature
    sed -i "7s/.*/$j/" input.txt
    
    # change the job.sh file line 4 to the current job name
    sed -i "4s/.*/#$ -N H$H-T$j/" $jobfile

    # print the line 7 of the input.txt file
    Tinput=$(sed -n '7p' input.txt)
    echo "Tinput = $Tinput"

    # Send Simulation
    qsub $jobfile

    sleep 5
    
done
