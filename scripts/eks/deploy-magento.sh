#!/bin/bash

# aws eks update-kubeconfig --region us-east-1 --name aws-demo

# Storage
kubectl -n magento-demo-production apply -f 11-storage/11.1-pv-var-log.yaml
kubectl -n magento-demo-production apply -f 11-storage/11.2-pvc-var-log.yaml
kubectl -n magento-demo-production apply -f 11-storage/12.1-pv-var-report.yaml
kubectl -n magento-demo-production apply -f 11-storage/12.2-pvc-var-report.yaml
kubectl -n magento-demo-production apply -f 11-storage/13.1-pv-var-export.yaml
kubectl -n magento-demo-production apply -f 11-storage/13.2-pvc-var-export.yaml
kubectl -n magento-demo-production apply -f 11-storage/14.1-pv-var-import.yaml
kubectl -n magento-demo-production apply -f 11-storage/14.2-pvc-var-import.yaml
kubectl -n magento-demo-production apply -f 11-storage/15.1-pv-var-importexport.yaml
kubectl -n magento-demo-production apply -f 11-storage/15.2-pvc-var-importexport.yaml
kubectl -n magento-demo-production apply -f 11-storage/16.1-pv-pub-media.yaml
kubectl -n magento-demo-production apply -f 11-storage/16.2-pvc-pub-media.yaml

# Magento
# TODO: Currently is NOT connected to persistent storage. For some reason
# Magento front and admin fail readiness/liveness checks.
kubectl apply -f 1-namespace.yaml
kubectl -n magento-demo-production apply -f 3-redis-fpc-deployment.yaml
kubectl -n magento-demo-production apply -f 4-elasticsearch-deployment.yaml
kubectl -n magento-demo-production apply -f 5-rabbitmq-deployment.yaml
kubectl -n magento-demo-production apply -f 6-redis-fpc-service.yaml
kubectl -n magento-demo-production apply -f 7-elasticsearch-service.yaml
kubectl -n magento-demo-production apply -f 8-rabbitmq-service.yaml
kubectl -n magento-demo-production apply -f 9-redis-sessions.yaml
kubectl -n magento-demo-production apply -f 10-database.yaml
kubectl -n magento-demo-production apply -f 17-image-secret.yaml
kubectl -n magento-demo-production apply -f 2-configmap.yaml
kubectl -n magento-demo-production apply -f 18.1-magento-admin-phpfpm.yaml
kubectl -n magento-demo-production apply -f 18.2-magento-admin-nginx.yaml
kubectl -n magento-demo-production apply -f 19-magento-cron-phpfpm.yaml
kubectl -n magento-demo-production apply -f 20.1-magento-front-phpfpm.yaml
kubectl -n magento-demo-production apply -f 20.2-magento-front-nginx.yaml
kubectl -n magento-demo-production apply -f 20.3-magento-front-phpfpm-hpa.yaml

# Ingress
# TODO