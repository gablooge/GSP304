#!/bin/bash
gcloud auth revoke --all

while [[ -z "$(gcloud config get-value core/account)" ]]; 
do echo "waiting login" && sleep 2; 
done

while [[ -z "$(gcloud config get-value project)" ]]; 
do echo "waiting project" && sleep 2; 
done



export PROJECT_ID=$(gcloud info --format='value(config.project)')

gsutil cp gs://${PROJECT_ID}/echo-web.tar.gz .
tar -xvzf echo-web.tar.gz

gcloud config set compute/zone us-central1-a 
gcloud container clusters create echo-cluster \
--num-nodes 2 \
--machine-type n1-standard-2



export PROJECT_ID=$(gcloud info --format='value(config.project)')
docker build -t echo-app:v1 .
docker tag echo-app:v1 gcr.io/${PROJECT_ID}/echo-app:v1
docker push gcr.io/${PROJECT_ID}/echo-app:v1

gcloud config set compute/zone us-central1-a 
gcloud container clusters get-credentials echo-cluster
kubectl run echo-app --image=gcr.io/${PROJECT_ID}/echo-app:v1 --port 8000


kubectl create deployment echo-app --image=gcr.io/${PROJECT_ID}/echo-app:v1

kubectl expose deployment echo-app --type=LoadBalancer --port 80 --target-port 8000


export EXTERNAL_IP=$(kubectl get service echo-app | awk 'BEGIN { cnt=0; } { cnt+=1; if (cnt > 1) print $4; }')
curl http://$EXTERNAL_IP

