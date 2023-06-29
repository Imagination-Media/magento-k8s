#!/bin/bash -x

# https://www.stacksimplify.com/aws-eks/eks-cluster/create-eks-cluster-nodegroups/

# Working values for EKS_INSTANCE - t3.medium(x86_64), t4g.medium(arm64)
# a1(fails), t4g, m6g, m6gd, c6g, c6gd, r6g, r6gd - are claimed to be supported on EKS
export EKS_INSTANCE="t4g.2xlarge"
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=
export EKS_CLUSTER=aws-demo
export EKS_REGION=us-east-1
export EKS_ZONES="us-east-1a,us-east-1b"
export EKS_KUBE_VERSION="1.27"
export EKS_KEY_NAME=aws-demo
export EKS_NODE_VOL_SIZE=100
export EKS_NG_MIN=2
export EKS_NG_DESIRED=2
export EKS_NG_MAX=3

eksctl create cluster --name=${EKS_CLUSTER} --region=${EKS_REGION} --zones=${EKS_ZONES} --version=${EKS_KUBE_VERSION} --without-nodegroup
eksctl utils associate-iam-oidc-provider --region ${EKS_REGION} --cluster ${EKS_CLUSTER} --approve

# Arm64 requirements
eksctl utils update-coredns --region ${EKS_REGION} --cluster ${EKS_CLUSTER} --approve
eksctl utils update-kube-proxy --region ${EKS_REGION} --cluster ${EKS_CLUSTER} --approve
eksctl utils update-aws-node --region ${EKS_REGION} --cluster ${EKS_CLUSTER} --approve

eksctl create nodegroup --cluster=${EKS_CLUSTER} \
                        --region=${EKS_REGION} \
                        --name=${EKS_CLUSTER}-ng \
                        --node-type=${EKS_INSTANCE} \
                        --nodes=${EKS_NG_DESIRED}  \
                        --nodes-min=${EKS_NG_MIN}  \
                        --nodes-max=${EKS_NG_MAX}  \
                        --node-volume-size=${EKS_NODE_VOL_SIZE} \
                        --ssh-access \
                        --ssh-public-key=${EKS_KEY_NAME} \
                        --managed  \
                        --asg-access  \
                        --external-dns-access  \
                        --full-ecr-access \
                        --appmesh-access  \
                        --alb-ingress-access  \
                        --node-volume-type=gp3  \

# Set up EFS
ATTACH_POLICY_ARN=$(aws iam create-policy --region=${EKS_REGION} \
    --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
    --policy-document file://iam-policy-example.json | cut -d'"' -f4)

eksctl create iamserviceaccount \
    --cluster ${EKS_CLUSTER} \
    --namespace kube-system \
    --name efs-csi-controller-sa \
    --attach-policy-arn ${ATTACH_POLICY_ARN} \
    --approve \
    --region ${EKS_REGION}

aws eks update-kubeconfig --region ${EKS_REGION} --name ${EKS_CLUSTER}

kubectl apply -f public-ecr-driver.yaml

vpc_id=$(aws eks describe-cluster \
    --name ${EKS_CLUSTER} \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --output text)

cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text \
    --region ${EKS_REGION})

security_group_id=$(aws ec2 create-security-group \
    --group-name EfsSecurityGroup \
    --description "EFS security group" \
    --vpc-id $vpc_id \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 2049 \
    --cidr $cidr_range

file_system_id=$(aws efs create-file-system \
    --region ${EKS_REGION} \
    --performance-mode generalPurpose \
    --query 'FileSystemId' \
    --output text)

subnets_list=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'Subnets[*].{SubnetId: SubnetId}' \
    --output text)

for subnet in $subnets_list
do
    echo "Creating mount target for $subnet"
    aws efs create-mount-target \
    --file-system-id $file_system_id \
    --subnet-id $subnet \
    --security-groups $security_group_id
done


