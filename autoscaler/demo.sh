#!/bin/bash

. $(dirname ${BASH_SOURCE})/../util.sh

SOURCE_DIR=$PWD

desc "A Knative Service that consumes resources"
run "cat $(relative service.yaml)"

backtotop

IP_ADDRESS=$(kubectl get svc knative-ingressgateway -n istio-system -o 'jsonpath={.status.loadBalancer.ingress[0].ip}')

# echo "IP: $IP_ADDRESS"
# read -s

desc "Create this new Service:"
run "kubectl apply -f $(relative service.yaml)"
run "kubectl get pod -w"

desc "Calling our new service"

desc "Let's figure out its domain/hostname"
run "kubectl get services.serving.knative.dev autoscale-go  -o=custom-columns=NAME:.metadata.name,DOMAIN:.status.domain"

HOST_URL=$(kubectl get services.serving.knative.dev autoscale-go  -o jsonpath='{.status.domain}')

# echo "Host: $HOST_URL"
# read -s

desc "Calling our service: "
run "curl -H \"Host: ${HOST_URL}\" \"http://${IP_ADDRESS}?sleep=100&prime=1000000&bloat=50\""


tmux split-window -v -d -c ~/go/src/github.com/knative/docs/
tmux select-pane -t 0
tmux send-keys -t 1 "go run serving/samples/autoscale-go/test/test.go -sleep 100 -prime 1000000 -bloat 50 -qps 9999 -concurrency 10 --ip $IP_ADDRESS" C-m
read -s 

kubectl port-forward -n monitoring $(kubectl get pods -n monitoring --selector=app=grafana --output=jsonpath="{.items..metadata.name}") 3000 > /dev/null 2>&1 &
PID=$!

desc "watch the load factor and autoscaling"
run "kubectl get deploy --watch"

desc "end demo"
read -s

kill $PID