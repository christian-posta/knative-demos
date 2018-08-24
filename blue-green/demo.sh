#!/bin/bash

. $(dirname ${BASH_SOURCE})/../util.sh

SOURCE_DIR=$PWD

desc "Create a Knative Configuration"
run "cat $(relative blue-green-demo-config.yaml)"

backtotop

IP_ADDRESS=$(kubectl get svc knative-ingressgateway -n istio-system -o 'jsonpath={.status.loadBalancer.ingress[0].ip}')

# echo "IP: $IP_ADDRESS"
# read -s

desc "Create this new Configuration:"
run "kubectl apply -f $(relative blue-green-demo-config.yaml)"
run "kubectl get pod -w"

backtotop

desc "We have no way of calling our service yet, so let's create a Knative Route:"
run "cat $(relative blue-green-demo-route.yaml)"

run "kubectl apply -f $(relative blue-green-demo-route.yaml)"

HOST_URL="blue-green-demo.default.example.com"


# echo "Host: $HOST_URL"
# read -s

desc "Calling our service: "

tmux split-window -v -d -c $SOURCE_DIR
tmux select-pane -t 0
tmux send-keys -t 1 "curl -H \"Host: ${HOST_URL}\" \"http://${IP_ADDRESS}\"" C-m
read -s 

backtotop
desc "Now lets deploy configuration for v2 of our service (green)"
run "cat $(relative blue-green-demo-config.1.yaml)"

desc "create the new configuration which should spawn a new revision"
run "kubectl apply -f $(relative blue-green-demo-config.1.yaml)"

run "kubectl get pod -w"
run "kubectl get revisions.serving.knative.dev"

backtotop
desc "Now we can change our routing rules to account for revision 2"
run "cat $(relative blue-green-demo-route-staged-v2.yaml)"

run "kubectl apply -f $(relative blue-green-demo-route-staged-v2.yaml)"


desc "As a client, I don't see the new version though!"
#tmux send-keys -t 1 "curl -H \"Host: ${HOST_URL}\" \"http://${IP_ADDRESS}\"" C-m

desc "Knative did create a staged v2 for us though. We can still get to it!"
#tmux send-keys -t 1 "curl -H \"Host: v2.${HOST_URL}\" \"http://${IP_ADDRESS}\"" C-m
read -s

backtotop
desc "If we're comfortable with this change, we can slowly migrate traffic"
run "cat $(relative blue-green-demo-route-canary-50-50.yaml)"

run "kubectl apply -f $(relative blue-green-demo-route-canary-50-50.yaml)"
backtotop
desc "Now if we're satisfied, we can route all traffic to v2/green"
run "cat $(relative blue-green-demo-route-v2.yaml)"

run "kubectl apply -f $(relative blue-green-demo-route-v2.yaml)"

