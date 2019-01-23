#!/bin/bash

printUsage() {
  echo "Usage:"
  echo "$0 [OPTIONS]"
  echo -e "\n  OPTIONS:"
  #echo "       addUsecase1: Introduces issues in the ICP4D cluster for students to resolve"
  echo "       addUsecase1Advance: Advance version of Usecase 1"
  echo "       fixUsecases: Removes the introduced issues in the ICP4D cluster"
  echo
  exit 0
}


setup() {
 
 echo "Authenticating Kubectl, assuming this is a standaalone install"
 . /ibm/InstallPackage/icp-patch/kubectl-auth.sh localhost
}
addUsecase1() {
    #1. Remove Kafka & stop IIS Server
    echo "Preparing Usecase 1"
    kubectl scale sts zookeeper --replicas=0 -n zen
    #kubectl exec -n zen $(kubectl get pods -n zen | grep services |  awk '{print $1}')  --  /opt/IBM/InformationServer/wlp/bin/server stop iis
    sleep 2m
    echo "Introduced Usecase 2"
}

addUsecase1Advance() {
        echo "Please dont terminate the process....It will take around couple of minutes"
	zoo=$(kubectl get pods -n zen -o wide | grep zook |  awk '{print $7}')
	
        kubectl scale sts zookeeper --replicas=0 -n zen > /dev/null 2>&1
	echo "Step 1 Complete"
        sleep 30s
   
        ssh $zoo "docker rmi  mycluster.icp:8500/zen/zookeeper:3.4.11" > /dev/null 2>&1
        echo "Step 2  Complete"
	sleep 30s
	
	
        yes | gluster volume stop image-manager force > /dev/null 2>&1
        echo "Step 3 Complete"
	sleep 1m
	
	
        kubectl scale sts zookeeper --replicas=1 -n zen > /dev/null 2>&1
	echo "Step 4 Complete"
        echo "Sleeping for 2 minutes for cluster to fail."
        sleep 2m

}
addUsecases2() {
    #2 Timesync Error 
    echo "Preparing Usecase 2"
    systemctl stop ntp;timedatectl set-ntp no
    timedatectl set-time 00:00:00
    if [ "00" == `date +%H` ]; then 
       echo "Time is out of sync"
    fi
    sleep 2m
    echo "Introduced Usecase 2"
}
addUsecases3() {
    #ImagepullBack Error
    echo "Preparing Usecase 3"
    yes | gluster volume stop image-manager
    kubectl delete pod $(kubectl get pods -n zen | grep mongo | awk '{print $1}')
    sleep 2m
    echo "Introduced Usecase 3"
}
addUsecases4() {

    #4 PVC Related Errors
    echo "Preparing Usecase 4"
    ddepvc = $(kubectl get pvc  --no-headers cognos-dde-daas -n zen  | awk '{print $3}')
    yes | gluster volume stop $ddepvc
    sleep 2m
    echo "Introduced Usecase 4"
}

addUsecases() {

    #3 MONGO IMAGE PULLBACK ERROR, Turn down image-manager volume and delete mongodb
    #docker save mycluster.icp:8500/zen/mongodb:4.0.1-debian-9  > mongo.tar
    #docker load < mongo.tar
    #docker rm mycluster.icp:8500/zen/mongodb:4.0.1-debian-9 
    sleep 2m
}

fixUsecases() {
	kubectl scale sts zookeeper --replicas=0 -n zen
        sleep 30s
        gluster volume start  image-manager
        sleep 30s
        kubectl scale sts zookeeper --replicas=1 -n zen
        sleep 30s

}
fixUsecasesOthers() {

    #1. Remove Kafka
    kubectl scale sts zookeeper --replicas=1 -n zen
    #kubectl exec -n zen $(kubectl get pods -n zen | grep services |  awk '{print $1}')  --  /opt/IBM/InformationServer/wlp/bin/server start iis

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
elif [ "$1" == "addUsecase1" ]; then
    addUsecase1
elif [ "$1" == "addUsecase1Advance" ]; then
    addUsecase1Advance
elif [ "$1" == "fixUsecases" ]; then
    fixUsecases
fi
