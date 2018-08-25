#!/usr/bin/env bash

FABRIC_PATH=/tmp/fabric
KAFKA_PATH=/tmp/kafka

# Create fabric shared dir
echo -e "\nCreating farbic network shared dir..."
if [ -d "$FABRIC_PATH" ]; then
  rm -rf $FABRIC_PATH
fi
mkdir -p $FABRIC_PATH/ledger/orderer{0,1,2}

# Create kafka data dir
echo -e "\nCreating kafka data dir..."
if [ -d "$KAFKA_PATH" ]; then
  rm -rf $KAFKA_PATH
fi
mkdir -p $KAFKA_PATH/datadir-kafka-{0,1,2,3}

###############################################

if [ -d "${PWD}/config" ]; then
    KUBECONFIG_FOLDER=${PWD}/config
else
    echo "Configuration files are not found."
    exit
fi

# Creating namespaces
echo -e "\nCreating required k8s namespaces..."
kubectl create -f ${KUBECONFIG_FOLDER}/namespaces.yaml

# Creating persistant volumes
echo -e "\nCreating persistant volumes..."
kubectl create -f ${KUBECONFIG_FOLDER}/kafka-pvs.yaml
kubectl create -f ${KUBECONFIG_FOLDER}/fabric-pvs.yaml

# Creating persistant volume claims
echo -e "\nCreating persistant volume claims..."
kubectl create -f ${KUBECONFIG_FOLDER}/kafka-pvcs.yaml
kubectl create -f ${KUBECONFIG_FOLDER}/fabric-pvcs.yaml

# Checking PVC status
checkPVCStatus() {
  if [ "$1" == "shared-pvc" ]; then
    if [ "$(kubectl get pvc -n fabric | grep $1 | awk '{print $2}')" == "Bound" ]; then
      echo "PVC $1:  bound!"
    fi
  else
    if [ "$(kubectl get pvc --all-namespaces | grep $1 | awk '{print $3}')" == "Bound" ]; then
      echo "PVC $1:  bound!"
    fi
  fi
}

PVCS="shared-pvc datadir-kafka-0 datadir-kafka-1 datadir-kafka-2 datadir-kafka-3"
for pvc in $PVCS
do
  checkPVCStatus $pvc
done


# Copy the required files(configtx.yaml, cruypto-config.yaml, sample chaincode etc.) into volume
echo -e "\nCreating Copy artifacts job..."
kubectl create -f ${KUBECONFIG_FOLDER}/job/0copy-artifacts.yaml

pod=$(kubectl get pods -n fabric --selector=job-name=copyartifacts --output=jsonpath={.items..metadata.name})
podSTATUS=$(kubectl get pods -n fabric --selector=job-name=copyartifacts --output=jsonpath={.items..phase})

while [ "${podSTATUS}" != "Running" ]; do
  echo "Wating for container of copy artifact pod to run. Current status of ${pod} is ${podSTATUS}"
  sleep 5;
  if [ "${podSTATUS}" == "Error" ]; then
    echo "There is an error in copyartifacts job. Please check logs."
    exit 1
  fi
  podSTATUS=$(kubectl get pods -n fabric --selector=job-name=copyartifacts --output=jsonpath={.items..phase})
done

echo -e "${pod} is now ${podSTATUS}"
echo -e "\nStarting to copy artifacts in persistent volume."
kubectl cp -n fabric ./artifacts $pod:/shared/

echo "Waiting for 10 more seconds for copying artifacts to avoid any network delay"
sleep 10
JOBSTATUS=$(kubectl get jobs -n fabric |grep "copyartifacts" |awk '{print $3}')
while [ "${JOBSTATUS}" != "1" ]; do
    echo "Waiting for copyartifacts job to complete"
    sleep 1;
    PODSTATUS=$(kubectl get pods -n fabric | grep "copyartifacts" | awk '{print $4}')
        if [ "${PODSTATUS}" == "Error" ]; then
            echo "There is an error in copyartifacts job. Please check logs."
            exit 1
        fi
    JOBSTATUS=$(kubectl get jobs -n fabric |grep "copyartifacts" |awk '{print $3}')
done
echo "Copy artifacts job completed"



# Generate Network artifacts using configtx.yaml and crypto-config.yaml
echo -e "\nGenerating the required artifacts for Blockchain network"
kubectl create -f ${KUBECONFIG_FOLDER}/job/1gen-artifacts.yaml

JOBSTATUS=$(kubectl get jobs -n fabric |grep utils|awk '{print $3}')
while [ "${JOBSTATUS}" != "1" ]; do
    echo "Waiting for generateArtifacts job to complete"
    sleep 1;
    UTILSSTATUS=$(kubectl get pods -n fabric | grep "utils" | awk '{print $4}')
    if [ "${UTILSSTATUS}" == "Error" ]; then
            echo "There is an error in utils job. Please check logs."
            exit 1
    fi
    JOBSTATUS=$(kubectl get jobs -n fabric |grep utils|awk '{print $3}')
done


# Setup zookeeper ensemble
echo -e "\nCreating Zookeeper service..."
kubectl create -f ${KUBECONFIG_FOLDER}/zookeeper
sleep 30

# Setup Kafka cluster
echo -e "\nCreating Kafka cluster service..."
kubectl create -f ${KUBECONFIG_FOLDER}/kafka
sleep 5

# Create services for all peers, ca, orderer
echo -e "\nCreating Fabric CA services..."
kubectl create -f ${KUBECONFIG_FOLDER}/ca
sleep 5

echo -e "\nCreating Fabric Orderer nodes..."
kubectl create -f ${KUBECONFIG_FOLDER}/orderer
sleep 5

echo -e "\nCreating Fabric peer nodes..."
kubectl create -f ${KUBECONFIG_FOLDER}/peer
sleep 5

echo -e "\nCreating Fabric CLI nodes..."
kubectl create -f ${KUBECONFIG_FOLDER}/cli
sleep 5

echo "Checking if all deployments are ready"

NUMPENDING=$(kubectl get deployments --all-namespaces -l app=hyperledger | awk '{print $6}' | grep 0 | wc -l | awk '{print $1}')
while [ "${NUMPENDING}" != "0" ]; do
    echo "Waiting on pending deployments. Deployments pending = ${NUMPENDING}"
    NUMPENDING=$(kubectl get deployments --all-namespaces -l app=hyperledger | awk '{print $6}' | grep 0 | wc -l | awk '{print $1}')
    sleep 1
done

echo "Waiting for 30 seconds for peers and orderer to settle"
sleep 30


# Generate channel artifacts using configtx.yaml and then create channel
echo -e "\nCreating channel transaction artifact and a channel"
kubectl create -f ${KUBECONFIG_FOLDER}/job/2create-channel.yaml

JOBSTATUS=$(kubectl get jobs -n fabric |grep createchannel |awk '{print $3}')
while [ "${JOBSTATUS}" != "1" ]; do
    echo "Waiting for createchannel job to be completed"
    sleep 1;
    if [ "$(kubectl get pods -n fabric | grep createchannel | awk '{print $4}')" == "Error" ]; then
        echo "Create Channel Failed"
        exit 1
    fi
    JOBSTATUS=$(kubectl get jobs -n fabric |grep createchannel |awk '{print $3}')
done
echo "Create Channel Completed Successfully"


# Join all peers on a channel
echo -e "\nCreating joinchannel job"
kubectl create -f ${KUBECONFIG_FOLDER}/job/3join-channel.yaml

JOBSTATUS=$(kubectl get jobs -n fabric |grep joinchannel |awk '{print $3}')
while [ "${JOBSTATUS}" != "1" ]; do
    echo "Waiting for joinchannel job to be completed"
    sleep 1;
    if [ "$(kubectl get pods -n fabric | grep joinchannel | awk '{print $4}')" == "Error" ]; then
        echo "Join Channel Failed"
        exit 1
    fi
    JOBSTATUS=$(kubectl get jobs -n fabric |grep joinchannel |awk '{print $3}')
done
echo "Join Channel Completed Successfully"

# Update channel anchor peers
echo -e "\nCreatiing updateanchor job"
kubectl create -f ${KUBECONFIG_FOLDER}/job/4update-anchor.yaml

BSTATUS=$(kubectl get jobs -n fabric |grep updateanchor |awk '{print $3}')
while [ "${JOBSTATUS}" != "1" ]; do
    echo "Waiting for updateanchor job to be completed"
    sleep 1;
    if [ "$(kubectl get pods -n fabric | grep updateanchor | awk '{print $4}')" == "Error" ]; then
        echo "Join Channel Failed"
        exit 1
    fi
    JOBSTATUS=$(kubectl get jobs -n fabric |grep updateanchor |awk '{print $3}')
done
echo "Update Channel Anchor Peer  Completed Successfully"


# Install chaincode on each peer
echo -e "\nCreating installchaincode job"
kubectl create -f ${KUBECONFIG_FOLDER}/job/5install-chaincode.yaml

JOBSTATUS=$(kubectl get jobs -n fabric |grep chaincodeinstall |awk '{print $3}')
while [ "${JOBSTATUS}" != "1" ]; do
    echo "Waiting for chaincodeinstall job to be completed"
    sleep 1;
    if [ "$(kubectl get pods -n fabric | grep chaincodeinstall | awk '{print $4}')" == "Error" ]; then
        echo "Chaincode Install Failed"
        exit 1
    fi
    JOBSTATUS=$(kubectl get jobs -n fabric |grep chaincodeinstall |awk '{print $3}')
done
echo "Chaincode Install Completed Successfully"


# Instantiate chaincode on channel
echo -e "\nCreating chaincodeinstantiate job"
echo "Running: kubectl create -f ${KUBECONFIG_FOLDER}/chaincode_instantiate.yaml"
kubectl create -f ${KUBECONFIG_FOLDER}/job/6instantiate-chaincode.yaml

JOBSTATUS=$(kubectl get jobs -n fabric |grep chaincodeinstantiate |awk '{print $3}')
while [ "${JOBSTATUS}" != "1" ]; do
    echo "Waiting for chaincodeinstantiate job to be completed"
    sleep 1;
    if [ "$(kubectl get pods -n fabric | grep chaincodeinstantiate | awk '{print $4}')" == "Error" ]; then
        echo "Chaincode Instantiation Failed"
        exit 1
    fi
    JOBSTATUS=$(kubectl get jobs -n fabric |grep chaincodeinstantiate |awk '{print $3}')
done
echo "Chaincode Instantiation Completed Successfully"

sleep 15
echo -e "\nNetwork Setup Completed !!"
