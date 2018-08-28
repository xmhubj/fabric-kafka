# Fabric Network with Kafka

A fully automated way to setup Hyperledger Fabric Network with Kafka Consensus on Kubernetes.

## Introduction

The Hyperledger Fabric has introduced Kafka as it’s primary consensus mechanism among the orderers. While in development, for testing purposes, a solo config orderer is used. However, in production, you need to have multiple orderer nodes set up to have fail proof systems.

## Network Topology

A simple Fabric network configuration:

- 2 CAs, 1 for each orgs
- 2 CLI, 1 for each orgs
- 3 Orderers
- 2 Organizations
- 4 peers, 2 for each orgs
- 4 Kafka broker instances
- 3 Zookeeper instances

## How to Use

### Prerequisites
- A single node K8S cluster bootstrapped by kubeadmin
- `git` is installed
- `kubectl` is installed

> Note: The automation scripts are only working on a single node kubernetes cluster, since dynamic storage provisioning is not configured by default. Required persistent volumes are created by the script `setupNetwork.sh`.

### Setup Fabric Netowrk
1. Clone the repository
```
$ git clone https://github.com/xmhubj/fabric-kafka.git
```

2. Change directory
```
$ cd fabric-kafka
```

3. Run the `setupNetwork.sh`
```
$ ./setupNetwork.sh
```

Please check the output of the above script, make sure no errors observed.

### Verify the Fabric Network
There are two additional deployments called `cli` added to the Fabric network, for debugging or testing purpose.

- Enter the `cli` container
```
$ kubectl exec -it cli-74bb65d9b7-r8c8d -n org1 bash
```

- Query the value of `a`, which should be the initial value `100`
```
$ peer chaincode query -C mychannel -n cc -c '{"Args":["query","a"]}'
```

- Execute action invoke, which will transfer `10` from `a` to `b`
```
$ peer chaincode invoke -o orderer0.ordererorg1:7050   -C mychannel -n cc -c '{"Args":["invoke","a","b","10"]}'
```

- Verify the value of `a`, which should be `90` aftering 
```
$ peer chaincode query -C mychannel -n cc -c '{"Args":["query","a"]}'
2018-08-27 04:09:00.475 UTC [msp] GetLocalMSP -> DEBU 001 Returning existing local MSP
2018-08-27 04:09:00.475 UTC [msp] GetDefaultSigningIdentity -> DEBU 002 Obtaining default signing identity
2018-08-27 04:09:00.475 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 003 Using default escc
2018-08-27 04:09:00.475 UTC [chaincodeCmd] checkChaincodeCmdParams -> INFO 004 Using default vscc
2018-08-27 04:09:00.475 UTC [chaincodeCmd] getChaincodeSpec -> DEBU 005 java chaincode disabled
2018-08-27 04:09:00.476 UTC [msp/identity] Sign -> DEBU 006 Sign: plaintext: 0A90070A6508031A0C08DCF28DDC0510...120263631A0A0A0571756572790A0161
2018-08-27 04:09:00.476 UTC [msp/identity] Sign -> DEBU 007 Sign: digest: C877E295D35A8229D66266C24310EC2BE717B7097386C953F36CE818A9879643
Query Result: 90
2018-08-27 04:09:00.497 UTC [main] main -> INFO 008 Exiting.....
```

### Delete the Fabric Network

```
$ ./deleteNetwork.sh
```

## References

- [hyperledger/fabric](https://github.com/hyperledger/fabric/tree/release-1.2/examples/e2e_cli)

- [hainingzhang/articles](https://github.com/hainingzhang/articles)

- [IBM/blockchain-network-on-kubernetes](https://github.com/IBM/blockchain-network-on-kubernetes/tree/master/images)
