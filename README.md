# Fabric Network with Kafka

Hyperledger Fabric Network with Kafka Consensus on Kubernetes.

## Introduction

The Hyperledger Fabric has introduced Kafka as it’s primary consensus mechanism among the orderers. While in development, for testing purposes, a solo config orderer is used. However, in production, you need to have multiple orderer nodes set up to have fail proof systems.

## Network Topology

A simple Fabric network configuration:

- 3 Orderers
- 2 Organizations
- 4 peers, 2 for each organizations
- 4 Kafka broker instances
- 3 Zookeeper instances


## References

- [hyperledger/fabric](https://github.com/hyperledger/fabric/tree/release-1.2/examples/e2e_cli)

- [skcript/Kafka-Fabric-Network](https://github.com/skcript/Kafka-Fabric-Network/edit/master/README.md)

- [IBM/blockchain-network-on-kubernetes](https://github.com/IBM/blockchain-network-on-kubernetes/tree/master/images)
