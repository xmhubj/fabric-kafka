#!/usr/bin/env bash

KUBECONFIG_FOLDER=${PWD}/config
JOB_FOLDER=${KUBECONFIG_FOLDER}/job

echo "Deleting kubernetes jobs..."
kubectl delete --ignore-not-found=true -f ${JOB_FOLDER}

echo "Deleting CA service and deployment..."
CACFG_FOLDER=${KUBECONFIG_FOLDER}/ca
kubectl delete --ignore-not-found=true -f ${CACFG_FOLDER}

echo "Deleting Peers..."
PEERCFG_FLODER=${KUBECONFIG_FOLDER}/peer
kubectl delete --ignore-not-found=true -f ${PEERCFG_FLODER}

echo "Deleting Oerderers..."
ORDERERCFG_FOLDER=${KUBECONFIG_FOLDER}/orderer
kubectl delete --ignore-not-found=true -f ${ORDERERCFG_FOLDER}

echo "Deleting CLI deployment..."
CLI_FOLDER=${KUBECONFIG_FOLDER}/cli
kubectl delete --ignore-not-found=true -f ${CLI_FOLDER}

echo "Deleting Kafka services..."
KAFKACFG_FOLDER=${KUBECONFIG_FOLDER}/kafka
kubectl delete --ignore-not-found=true -f ${KAFKACFG_FOLDER}

echo "Deleting Zookeeper services..."
ZKCFG_FOLDER=${KUBECONFIG_FOLDER}/zookeeper
kubectl delete --ignore-not-found=true -f ${ZKCFG_FOLDER}

echo "Deleting volumes..."
kubectl delete --ignore-not-found=true -f ${KUBECONFIG_FOLDER}/kafka-pvcs.yaml
kubectl delete --ignore-not-found=true -f ${KUBECONFIG_FOLDER}/kafka-pvs.yaml
kubectl delete --ignore-not-found=true -f ${KUBECONFIG_FOLDER}/fabric-pvcs.yaml
kubectl delete --ignore-not-found=true -f ${KUBECONFIG_FOLDER}/fabric-pvs.yaml

echo "Deleting namespaces..."
kubectl delete --ignore-not-found=true -f ${KUBECONFIG_FOLDER}/namespaces.yaml

sleep 15

echo -e "\npv:" 
kubectl get pv
echo -e "\npvc:"
kubectl get pvc
echo -e "\njobs:"
kubectl get jobs 
echo -e "\ndeployments:"
kubectl get deployments
echo -e "\nservices:"
kubectl get services
echo -e "\npods:"
kubectl get pods

echo -e "\nNetwork Deleted!!\n"

