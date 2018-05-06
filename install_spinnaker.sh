#!/bin/bash -xe

export REGION=europe-west1
export ZONE=$REGION-d

# Add function to simplify API enablement with gcloud
addapi(){
	if [ -z "$1" ]; then
		echo "Use the command passing the APIs you want to enable as arguments"
	else
		for i in "$@"
			do
				echo "Testing for $i API"
				if [[ $(gcloud services list --enabled --filter=$i --format 'yaml') ]]; then
					echo "API already enabled"
				else
					echo "Enabling API..."
					gcloud services enable $i
					echo "API enabled"
				fi
			done
	fi
}

# Enable APIs
addapi container.googleapis.com cloudresourcemanager.googleapis.com cloudbuild.googleapis.com storage-api.googleapis.com sourcerepo.googleapis.com

gcloud config set compute/zone $ZONE
gcloud container clusters create spinnaker-tutorial --machine-type=n1-standard-2
gcloud iam service-accounts create  spinnaker-storage-account  --display-name spinnaker-storage-account

# Needed to ensure SA gets role properly?

sleep 60
export SA_EMAIL=$(gcloud iam service-accounts list --filter="displayName:spinnaker-storage-account" --format='value(email)')
export PROJECT=$(gcloud info --format='value(config.project)')
gcloud projects add-iam-policy-binding $PROJECT --role roles/storage.admin --member serviceAccount:$SA_EMAIL
gcloud iam service-accounts keys create spinnaker-sa.json --iam-account $SA_EMAIL

export HELM_VERSION=2.7.2
wget https://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz
tar zxfv helm-v${HELM_VERSION}-linux-amd64.tar.gz
cp linux-amd64/helm .
# Cleanup helm installation
rm -rf linux-amd64
rm helm-v${HELM_VERSION}-linux-amd64.tar.gz

# Give tiller cluster-admin role service account
kubectl create clusterrolebinding user-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
kubectl create serviceaccount tiller --namespace kube-system
kubectl create clusterrolebinding tiller-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl create clusterrolebinding --clusterrole=cluster-admin --serviceaccount=default:default spinnaker-admin

# Initialize Helm
./helm init --service-account tiller
./helm update
# Give tiller a chance to start up
# TODO: Change this to polling
sleep 180
./helm version | grep ${HELM_VERSION}

export PROJECT=$(gcloud info --format='value(config.project)')
export BUCKET=$PROJECT-spinnaker-config
gsutil mb -c regional -l $REGION gs://$BUCKET

export SA_JSON=`cat spinnaker-sa.json`
export PROJECT=$(gcloud info --format='value(config.project)')
export BUCKET=$PROJECT-spinnaker-config
cat > spinnaker-config.yaml <<EOF
storageBucket: $BUCKET
gcs:
  enabled: true
  project: $PROJECT
  jsonKey: '$SA_JSON'

# Disable minio the default
minio:
  enabled: false

# Configure your Docker registries here
accounts:
- name: gcr
  address: https://gcr.io
  repositories:
  - $PROJECT/sample-app
  username: _json_key
  password: '$SA_JSON'
  email: 1234@5678.com
images:
  deck: quay.io/spinnaker/deck:v2.1095.0
EOF

./helm install -n cd stable/spinnaker -f spinnaker-config.yaml --version 0.3.1 --timeout 600

export DECK_POD=$(kubectl get pods --namespace default -l "component=deck" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward --namespace default $DECK_POD 8080:9000 >> /dev/null &
sleep 10
curl localhost:8080

kill %1
