# Continuous Delivery Pipelines with Spinnaker and Kubernetes

This repository is based on [these instructions](https://cloud.google.com/solutions/continuous-delivery-spinnaker-kubernetes-engine) from the official Google Cloud Platform (GCP) solution.
You can either follow them or use the instructions and scripts here to simplify the setup process.
I strongly recommend though you have a peek a the GCP solution, it includes the rationale behind the solution and some very useful diagrams. This repo does not explain what we're doing what we're doing and focuses instead on getting the installation done. 

You can follow all the steps in Cloud Shell. To clone this repo and open this very instructions, click on the following button:

[![Open in Cloud Shell](http://gstatic.com/cloudssh/images/open-btn.svg)](https://console.cloud.google.com/cloudshell/open?git_repo=https%3A%2F%2Fgithub.com%2Fsh3lld00m%2Fspinnaker-gke-cd-demo.git&page=shell&tutorial=Readme.md)

## Setup and install Spinnaker
Clone this repo:

```bash
git clone https://github.com/sh3lld00m/spinnaker-gke-cd-demo.git
```

Review the environment variable ```REGION``` in the script ìnstall_spinnaker.sh` to match your specific region. By default, the script will deploy the Kubernetes cluster where Spinnaker is going to run in Belgium (europe-west1). You can see a list of the available
running ```gcloud compute regions list```.

Once the change is done, run the script:

```bash
./install_spinnaker.sh
```

This script should take care of

- Enabling the APIs in your project	
- Create the Kubernetes cluster to host Spinnaker
- Configure necessary IAM to delegate permissions to Spinnaker
- Install Helm & configure Spinnaker
- Deploy the Spinnaker Helm chart

Once the script has finished, you should have Spinnaker ready and up & running. To connect to the Spinnaker UI,
just click **Web Preview** in Cloud Shell and click **Preview on port 8080**. You should see the Spinnaker welcome screen
in your browser.

If your Cloud Shell session gets closed, you can always re-establish the proxy connection running the following script:

```bash
./forward_spk_ui
```

## Building the Docker image

### Create your source code repositories

Change directories to source code:

```bash
cd sample-app
```

If you haven't configured Git before, uncomment the following lines in the ```git_setup.sh``` and replace both `EMAIL_ADDRESS` and ```USERNAME``` with your Git email address and username:

```bash
git config --global user.email "[EMAIL_ADDRESS]"
git config --global user.name "[USERNAME]"
```

Once done, run thee `git_setup.sh` script that will make sure the `sample-app` code gets uploaded to a Cloud Source Repository in your project:

```bash
./git_setup.sh
```

Check that you can see your source code in the Google Cloud Console:

[https://console.cloud.google.com/code/develop/browse/sample-app/master](https://console.cloud.google.com/code/develop/browse/sample-app/master)

### Configure your build triggers

Go to the [Build triggers page](https://console.cloud.google.com/gcr/triggers/add?_ga=2.21153467.-1043472229.1512401199) in the Container Registry
section of the Google Cloud Console. Select **Cloud Source Repository** and click **Continue**. Select your newly created `sample app`repository from the list, and click **Continue**.

Set the following trigger settings:

- **Name**: sample-app-tags
- **Trigger type**: Tag
- **Tag (regex)**: ```v.*```
- **Build configuration**: ```cloudbuild.yaml```
- **cloudbuild.yaml location**: ```/cloudbuild.yaml```

Click **Create trigger**. 

### Build your image

Go to your source code in Cloud Shell, create a Git tag:

```bash
git tag v1.0.0
```

Push the tag:

```bash
git push --tag
```

In **Container Registry** in the Cloud Console, click [**Build History**](https://console.cloud.google.com/gcr/builds?_ga=2.124750090.-1043472229.1512401199) to check that the build has been triggered.

## Configuring your deployment pipelines

Images are building now automatically. Now it is time to deploy them to the Kubernetes cluster.

We're going to deploy a scaled-down environment for integration testing. After the integration pass, you must manually approve the changes to deploy the code to production services.

### Create the application

1. In the Spinnaker UI, click **Actions**, then click **Create Application**.
2. In the **New Application** dialog, enter the following fields:
- **Name**: sample
- **Owner Email**: [your email address]
3. Click **Create**.

### Create service load balancers

In Cloud Shell, run the following command from the ```sample-app``` root directory:

```bash
kubectl apply -f k8s/services
```
### Create the deployment pipeline

1. From Cloud Shell, run the script ```pipeline_setup.sh``` in the ```sample-app``` section to upload an example pipeline to your Spinnaker instance.

2. In the Spinnaker UI, click **Pipelines** on the top navigation bar.

3. Click **Configure** in the ```Deploy``` pipeline. The continuous delivery pipeline configuration should appear in the UI.

### Test everything
From here, you can continue from the section **Run your pipeline manually** in the [solution documentation](https://cloud.google.com/solutions/continuous-delivery-spinnaker-kubernetes-engine) from the Google Cloud Platform web page.

## Shutting down the demo
Run the ```cleanup.sh``` script and if you want, proceed to remove your project.

