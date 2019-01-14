#!/bin/bash

Print_Usage() {
  echo "Usage:"
  echo "$0 [OPTIONS]"
  echo -e "\n  OPTIONS:"
  echo "       --add-lab-usecases: Introduces issues in the ICP4D cluster for students to resolve"
  echo "       --remove-lab-usecases: Removes the introduced issues in the ICP4D cluster"
  echo
  exit 0
}


setup() {
 
 echo "Authenticating Kubectl, assuming this is a standaalone install
 . /ibm/InstallPackage/icp-patch/kubectl-auth.sh localhost
}

add-usecases ()
{

    #1. Remove Kafka
    kubectl scale sts zookeeper --replicas=0 -n zen

    #2 Timesync Error
    systemctl stop ntp;timedatectl set-ntp no
    timedatectl set-time 00:00:00
    if [ "00" == `date +%H` ]; then 
       echo "Time is not in sync"
    fi

    #3 REDIS IMAGE PULLBACK ERROR
    #docker save mycluster.icp:8500/zen/mongodb:4.0.1-debian-9  > mongo.tar
    #docker load < mongo.tar
    #docker rm mycluster.icp:8500/zen/mongodb:4.0.1-debian-9 

    sleep 2m


}

remove-usecases ()
{

    #1. Remove Kafka
    kubectl scale sts zookeeper --replicas=1 -n zen

    #2 Timesync Error
    systemctl start ntp;timedatectl set-ntp yes
    
    
    #3 REDIS IMAGE PULLBACK ERROR
    #docker save mycluster.icp:8500/zen/mongodb:4.0.1-debian-9  > mongo.tar
    #docker load < mongo.tar
    #docker rm mycluster.icp:8500/zen/mongodb:4.0.1-debian-9 

    sleep 2m

}
