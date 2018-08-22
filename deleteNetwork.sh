
KUBECONFIG_FOLDER=${PWD}/config
JOB_FOLDER=${KUBECONFIG_FOLDER}/job

echo "Deleting kubernetes jobs..."
kubectl delete --ignore-not-found=true -f ${JOB_FOLDER}/chaincode_instantiate.yaml
kubectl delete --ignore-not-found=true -f ${JOB_FOLDER}/chaincode_install.yaml
kubectl delete --ignore-not-found=true -f ${JOB_FOLDER}/join_channel.yaml
kubectl delete --ignore-not-found=true -f ${JOB_FOLDER}/create_channel.yaml
kubectl delete --ignore-not-found=true -f ${JOB_FOLDER}/generateArtifactsJob.yaml
kubectl delete --ignore-not-found=true -f ${JOB_FOLDER}/copyArtifactsJob.yaml

echo "Deleting CA service and deployment..."
CACFG_FOLDER=${KUBECONFIG_FOLDER}/ca
kubectl delete --ignore-not-found=true -f ${CACFG_FOLDER}/ca-deployment.yaml
kubectl delete --ignore-not-found=true -f ${CACFG_FOLDER}/ca-service.yaml

echo "Deleting Peers..."
PEERCFG_FLODER=${KUBECONFIG_FOLDER}/peer
kubectl delete --ignore-not-found=true -f ${PEERCFG_FLODER}/peer-deployment.yaml
kubectl delete --ignore-not-found=true -f ${PEERCFG_FLODER}/peer-service.yaml

echo "Deleting Oerderers..."
ORDERERCFG_FOLDER=${KUBECONFIG_FOLDER}/orderer
kubectl delete --ignore-not-found=true -f ${ORDERERCFG_FOLDER}/orderer-deployment.yaml
kubectl delete --ignore-not-found=true -f ${ORDERERCFG_FOLDER}/orderer-service.yaml

echo "Deleting Kafka services..."
KAFKACFG_FOLDER=${KUBECONFIG_FOLDER}/kafka
kubectl delete --ignore-not-found=true -f ${KAFKACFG_FOLDER}/kafka-deployment.yaml
kubectl delete --ignore-not-found=true -f ${KAFKACFG_FOLDER}/kafka-service.yaml

echo "Deleting Zookeeper services..."
ZKCFG_FOLDER=${KUBECONFIG_FOLDER}/zookeeper
kubectl delete --ignore-not-found=true -f ${ZKCFG_FOLDER}/zk-deployment.yaml
kubectl delete --ignore-not-found=true -f ${ZKCFG_FOLDER}/zk-service.yaml

echo "Deleting volumes..."
kubectl delete --ignore-not-found=true -f ${KUBECONFIG_FOLDER}/createVolume.yaml

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

