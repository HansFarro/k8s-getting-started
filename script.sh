#!/bin/bash
REGION="us-central1"
CLUSTER_NAME="my-cluster"
PATH=$(pwd)

# FUNCIONES
function change_dir (){
  cd $PATH/$1
}

echo "Cambiar a directorio de terraform"
change_dir terraform
echo "Inicializar Terraform"
terraform init
terraform fmt
terraform plan
echo "Crear cluster de Kubernetes "
terraform apply -auto-approve

gcloud container clusters get-credentials --region $REGION $CLUSTER_NAME