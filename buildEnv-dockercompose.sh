#!/bin/bash

####################################################################################################
#	Author : Alex Dominic Savio								                                       #
#	Organization : Hewlett-Packard Enterprise						   							   #
#	Email : alex.william@hpe.com								   								   #
#												                                                   #
# Purpose:											                                               #
# This script gets the hostname and ipaddress as input through command line option.                #
# It automatically invokes the docker-compose up -d command to download				               #
# and spawn the HPE Cloud Service Automation CE  containers.							           #
####################################################################################################


hostname=$1
ipaddress=$2
proxyhost=$3
proxyport=$4

if [ "$1" = "" ]; then
    echo -e "USAGE:\nsh buildEnv-dockercompose.sh <hostname> <ipaddress> [<proxy host> <proxy port>]"
    echo -e "\nThis script gets the hostname and ipaddress as input through command line option.\nIt automatically invokes the docker-compose up command to download and spawn containers."
    echo -e "\nProxy host and proxy port are optional"
    hostname=`hostname`
    ipaddress=`ifconfig eth0 2>/dev/null|awk '/inet addr:/ {print $2}'|sed 's/addr://'`
    echo -e "Possible value hostname = $hostname and ipaddress = $ipaddress"
    exit
fi

if [  -z "$hostname" -a "$hostname"=" " ]; then
    echo -e "Please pass hostname as command line input\n"
    echo -e "USAGE:\nsh buildEnv-dockercompose.sh <hostname> <ipaddress> [<proxy host> <proxy port>]"
    exit
fi

if [  -z "$ipaddress" -a "$ipaddress"=" " ]; then
    echo -e "Please pass ipaddress as command line input\n"
    echo -e "USAGE:\nsh buildEnv-dockercompose.sh <hostname> <ipaddress> [<proxy host> <proxy port>]"
    exit
fi

ping -q -c5 $ipaddress  > /dev/null

if [ $? -eq 0 ]; then
    echo "IPAddress : $ipaddress validation successfull"
else
    echo " Unable to reach $ipaddress"
    exit
fi

echo "The hostname is  $hostname"
echo "The ipaddress is $ipaddress"

if [ ! -z "$hostname" ] && [ "$hostname"!=" " ] && [ ! -z "$ipaddress" ] && [ "$ipaddress"!=" " ]; then
    if [ ! -f docker-compose.yml ]; then
        echo "Local Copy do not exist, download docker-compose.yml from github"
        wget https://raw.githubusercontent.com/albert748/csa-ce/master/docker-compose.yml --no-check-certificate
    fi

    echo "Changing the  hostname and ipaddress in the yml file"
    sed -i -e "s/vmhostname/${hostname}/" -e "s/vmipaddress/${ipaddress}/" -e "s/proxyhost/${proxyhost}/" -e "s/proxyport/${proxyport}/"  docker-compose.yml
    echo "Starting to download all the required images and the containers will be created in the backgroud. This may take sevaral minutes."

    docker-compose up -d

    echo "Please note the below URLs for your reference"
    echo "CSA Management Console - https://$ipaddress:18444/csa"
    echo "MPP - https://$ipaddress:18089/mpp"
    echo "Operations Orchestration Central - https://$ipaddress:18445/oo"
fi
