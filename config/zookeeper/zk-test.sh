# It is better to test zookeeper ensemble with API
# - create a key/value pair
# - verfiy the value of the key created
kubectl exec zoo-0 --namespace=kafka -- /zookeeper-3.4.9/bin/zkCli.sh create /foo bar
kubectl exec zoo-2 --namespace=kafka -- /zookeeper-3.4.9/bin/zkCli.sh get /foo
