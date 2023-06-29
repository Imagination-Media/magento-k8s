#!/bin/bash


export EKS_CLUSTER=aws-demo
export EKS_REGION=us-east-1

aws eks update-kubeconfig --region ${EKS_REGION} --name ${EKS_CLUSTER}

# Storage
kubectl -n magento-demo-production apply -f 11-storage-efs/11.1-pv-var-log.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/11.2-pvc-var-log.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/12.1-pv-var-report.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/12.2-pvc-var-report.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/13.1-pv-var-export.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/13.2-pvc-var-export.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/14.1-pv-var-import.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/14.2-pvc-var-import.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/15.1-pv-var-importexport.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/15.2-pvc-var-importexport.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/16.1-pv-pub-media.yaml
kubectl -n magento-demo-production apply -f 11-storage-efs/16.2-pvc-pub-media.yaml

# Magento
# Those Kubernetes manifests, whose path begins with "../scripts", have been
# re-used as-is. Others needed modifications. This is a subject for further
# work on templating a single multiplatform deploy.
# Eventually all Magento-related manifests should end up in "../scripts" directory.
kubectl apply -f ../scripts/1-namespace.yaml
kubectl -n magento-demo-production apply -f 3.1-redis-fpc-deployment.yaml
kubectl -n magento-demo-production apply -f 4.1-elasticsearch-deployment.yaml
kubectl -n magento-demo-production apply -f 5.1-rabbitmq-deployment.yaml
kubectl -n magento-demo-production apply -f ../scripts/6-redis-fpc-service.yaml
kubectl -n magento-demo-production apply -f ../scripts/7-elasticsearch-service.yaml
kubectl -n magento-demo-production apply -f ../scripts/8-rabbitmq-service.yaml
kubectl -n magento-demo-production apply -f 9.1-redis-sessions.yaml
kubectl -n magento-demo-production apply -f 10.1-database.yaml
kubectl -n magento-demo-production apply -f ../scripts/17-image-secret.yaml
kubectl -n magento-demo-production apply -f 2.1-configmap.yaml
kubectl -n magento-demo-production apply -f 18.1.1-magento-admin-phpfpm.yaml
kubectl -n magento-demo-production apply -f 19.1-magento-cron-phpfpm.yaml
kubectl -n magento-demo-production apply -f 20.1.1-magento-front-phpfpm.yaml
kubectl -n magento-demo-production apply -f 20.3.1-magento-front-phpfpm-hpa.yaml
