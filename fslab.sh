#!/bin/bash

printUsage() {
  echo "Usage:"
  echo "$0 [OPTIONS]"
  echo -e "\n  OPTIONS:"
  echo "       addUsecases: Introduces issues in the ICP4D cluster for students to resolve"
  echo "       fixUsecases: Removes the introduced issues in the ICP4D cluster"
  echo
  exit 0
}


setup() {
 
 echo "Authenticating Kubectl, assuming this is a standaalone install"
 . /ibm/InstallPackage/icp-patch/kubectl-auth.sh localhost
}

addUsecases() {

    #1. Remove Kafka & stop IIS Server
    kubectl scale sts zookeeper --replicas=0 -n zen
    kubectl exec -n zen $(kubectl get pods -n zen | grep services |  awk '{print $1}')  --  /opt/IBM/InformationServer/wlp/bin/server stop iis
	

    #2 Timesync Error
    systemctl stop ntp;timedatectl set-ntp no
    timedatectl set-time 00:00:00
    if [ "00" == `date +%H` ]; then 
       echo "Time is out of sync"
    fi

    #3 MONGO IMAGE PULLBACK ERROR, Turn down image-manager volume and delete mongodb
    #docker save mycluster.icp:8500/zen/mongodb:4.0.1-debian-9  > mongo.tar
    #docker load < mongo.tar
    #docker rm mycluster.icp:8500/zen/mongodb:4.0.1-debian-9 
 
    yes | gluster volume stop image-manager
    kubectl delete pod $(kubectl get pods -n zen | grep mongo | awk '{print $1}')
	
    #4 Turn down DDE related PVCs
    ddepvc = $(kubectl get pvc  --no-headers cognos-dde-daas -n zen  | awk '{print $3}')
    yes | gluster volume stop $ddepvc
	
    sleep 2m


}

fixUsecases() {

    #1. Remove Kafka
    kubectl scale sts zookeeper --replicas=1 -n zen
	kubectl exec -n zen $(kubectl get pods -n zen | grep services |  awk '{print $1}')  --  /opt/IBM/InformationServer/wlp/bin/server start iis

    #2 Timesync Error
    systemctl start ntp;timedatectl set-ntp yes
    service ntpd stop;ntpdate pool.ntp.org;service ntpd start
	
    #3 Turn up the image manager volume
    gluster volume start  image-manager
    kubectl delete pod $(kubectl get pods -n zen | grep mongo | awk '{print $1}')
	
    #4 Turn up DDE Volumes
	
    ddepvc=$(kubectl get pvc  --no-headers cognos-dde-daas -n zen  | awk '{print $3}')
    gluster volume start $ddepvc
	
	 
    #TEST gluster volume info | grep -B 4 Stopped
	
    sleep 2m
}

if [ "$1" == "help" ]; then
    printUsage
elif [ "$1" == "addUsecases" ]; then
    addUsecases
elif [ "$1" == "addUsecases" ]; then
    fixUsecases
fi
