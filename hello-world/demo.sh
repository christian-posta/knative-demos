#!/bin/bash

. $(dirname ${BASH_SOURCE})/../util.sh

SOURCE_DIR=$PWD

desc "A simple Knative Service"
run "cat $(relative service.yaml)"

backtotop

IP_ADDRESS=$(k get pod -n gloo-system -l  gloo=clusteringress-proxy -o jsonpath='{.items[0].status.hostIP}'):$(kubectl -n gloo-system get service clusteringress-proxy -o jsonpath='{.spec.ports[?(@.name=="http")].nodePort}')

# echo "IP: $IP_ADDRESS"
# read -s

desc "Create a Knative Service:"
run "kubectl apply -f $(relative service.yaml)"

desc "Calling our new service"
read -s 

desc "Let's figure out its domain/hostname"
run "kubectl get services.serving.knative.dev helloworld-go  -o=custom-columns=NAME:.metadata.name,DOMAIN:.status.domain"

HOST_URL=$(kubectl get services.serving.knative.dev helloworld-go  -o jsonpath='{.status.domain}')

# echo "Host: $HOST_URL"
# read -s

desc "Calling our service: "
run "curl -H \"Host: ${HOST_URL}\" http://${IP_ADDRESS}"