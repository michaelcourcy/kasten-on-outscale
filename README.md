# Kasten on Outscale

We demonstrate here how to use [Kasten] on the outscale platform : 

*   Build a simple kubernetes cluster with rancher (One RKE, One master and 3 worker nodes)
*   Install the CSI outscale driver to get dynamic PVC provisionning and Snapshot features
*   Install Kasten and demonstrate a backup and restore on a simple application.

# Build a rancher kubernetes cluster 

## Create the infrastructure with ocs cli and terraform  

### Create an EIM user and obtain the AK-SK

Go to the [cockpit interface](https://cockpit-eu-west-2.outscale.com) and create an [EIM User](https://wiki.outscale.net/display/EN/EIM+User+Interface) with proper policies to create the infrastructure. I used a policy with full access for quick starting, but you may customize it latter.

Use the [AK-SK of this EIM User](https://wiki.outscale.net/display/EN/Managing+Access+Keys+for+EIM+Users) so that you can use it for your client and terraform configuration.

### Install de osc-cli

Configure the client 

```
# we use pip3 
pip3 --version
pip 20.3.1 from /usr/local/lib/python3.9/site-packages/pip (python 3.9)
# adapt X.X depending of your version 
wget https://github.com/outscale/osc-cli/releases/download/vX.X.X/osc_sdk-X.X-py3-none-any.whl 
pip3 install osc_sdk-X.X-py3-none-any.whl
mkdir $HOME/.osc_sdk && cd $HOME/.osc_sdk
wget https://raw.githubusercontent.com/outscale/osc-cli/master/osc_sdk/config.json
```

Now change the content of the `config.json`file and test the cli work as expected 

```
osc-cli icu ListAccessKeys
{
    "accessKeys": [
        {
            "status": "ACTIVE",
            "tags": [],
            "createDate": "2021-02-08T13:11:06.000Z",
            "accessKeyId": "XXXXXXXXXXXXXXXX",
            "secretAccessKey": "YYYYYYYYYYYYYYYYYY",
            "expirationDate": null,
            "touchDate": "2021-02-08T13:11:06.000Z",
            "ownerId": "204741904112"
        }
    ],
    "marker": null,
    "isTruncated": false,
    "ResponseMetadata": {
        "RequestId": "9aa29d73-0782-4578-8692-f252bff9f7a1"
    }
}
```

### configure terraform 

#### Create a keypair to access your machines.

We'll need a ssh keypair to access your machine, install docker and run rancher container.

I create one based on my ssh keypair 

```
osc-cli fcu CreateKeyPair \
    --KeyName michael  
    --PublicKeyMaterial $(cat ~/.ssh/id_rsa.pub|base64) 
```

You may change the `KeyName`, this `KeyName` will be used in the [variable files](./terraform/variable.tf) of the terraform script.


#### Create env vars for terraform  

We now work on the terraform directory 
```
cd terraform
```

To execute terraform you need to export AK-SK you created previously.

```
export OUTSCALE_ACCESSKEYID="<YOUR_OUTSCALE_ACCESSKEYID>"
export OUTSCALE_SECRETKEYID="<YOUR_OUTSCALE_SECRETKEYID>"
```

#### Review terraform and variable files 

Check the terraform files. We basically create a public network and 3 private network in a VPC : 

In the public network we build the Rancher server and on the private networks we build the downstream cluster. See the [rancher architecture page](https://rancher.com/docs/rancher/v2.x/en/overview/architecture/) to better understand the link between rancher server and downstream cluster.

The rancher server is also used as a bastion to access the others nodes on the private network. 

We did not implement an [Authorized Cluster Endpoint](https://rancher.com/docs/rancher/v2.x/en/overview/architecture/#4-authorized-cluster-endpoint) because our goal is to quickly validate Kasten on Outscale, but that can be easily be done with an Outscale loadbalancers. 

In eu-west-2 there is 2 AZ available hence the first and third network is belonging to the same AZ.

Edit variable.tfvars and create your infrastructure 

```
# import the outscale provider and init a local terraform backend
terraform init 
# check your plan 
terraform plan 
# execute it 
terraform apply 
```

## Configure the machines 

Use the rancher server as a bastion to the other machines.

Here is an example 

```
terraform output 
cluster_1_master_1_private_ip = "10.0.1.253"
cluster_1_worker_1_private_ip = "10.0.1.193"
cluster_1_worker_2_private_ip = "10.0.2.51"
cluster_1_worker_3_private_ip = "10.0.3.27"
rke_vm_public_ip = "<public_ip>"


ssh-add  
ssh -A outscale@<public_ip>
# access to other machines from there
ssh -A outscale@10.0.1.253
ssh -A outscale@10.0.1.193
ssh -A outscale@10.0.2.51
ssh -A outscale@10.0.3.27
```

## Create the rancher server 

```
sudo apt-get update 
sudo apt install --assume-yes docker.io
sudo docker run --privileged -d --restart=unless-stopped -p 80:80 -p 443:443 rancher/rancher:stable
```

Access to https://<public_ip> follow the install wizard.


## Create the downstream cluster 

From the rancher server UI add a cluster using existing nodes https://<public_ip>/g/clusters/add/launch/custom. 

Obtain the command for provisioning master and worker nodes: 

### On master nodes 

Choose control plan and etcd role and use the generated command on cluster_1_master_1

```
sudo apt-get update 
sudo apt install --assume-yes docker.io
# use the command given by the ui to provision master node
# Depending of your options that should look like the one below. We use the same node for controle plan and etcd.
# sudo docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.5.8 --server https://<public_ip> --token <token> --ca-checksum <checksum> --etcd --controlplane
```

### On worker nodes 

Choose worker role and use the generated command on cluster_1_worker_1 cluster_1_worker_2 cluster_1_worker_3

```
sudo apt-get update 
sudo apt install --assume-yes docker.io
# use the command given by the ui to provision worker node
# Depending of your options that should look like the one below. 
# sudo docker run -d --privileged --restart=unless-stopped --net=host -v /etc/kubernetes:/etc/kubernetes -v /var/run:/var/run  rancher/rancher-agent:v2.5.8 --server https://<public_ip> --token <token> --ca-checksum <checksum> --worker
```

### Launch the downstream cluster creation

When the rancher server as identified the different nodes to create the cluster click the "Done" button and wait for the downstream cluster to be ready.

### Obtain the kubeconfig 

Once the kubernetes cluster is ready, through the rancher server UI download the kubeconfig file. Change the name of the context to a more meaningful name like "outscale-cluster-1", merge it to your config file and set it as your current context. 

```
kubectl konfig import -s kubeconfig
kubectl config use-context outscale-cluster-1
kubectl get nodes
NAME            STATUS   ROLES               AGE   VERSION
ip-10-0-1-193   Ready    worker              18d   v1.20.6
ip-10-0-1-253   Ready    controlplane,etcd   18d   v1.20.6
ip-10-0-2-51    Ready    worker              18d   v1.20.6
ip-10-0-3-27    Ready    worker              18d   v1.20.6
```

You're ready now install the outscale CSI driver.


# Install the CSI Driver

Outscale feature an outscale CSI Driver that is also snapshot feature enabled. This is going to make things much easier for taking snaphot with kasten. 

## Follow the Readme for initial set up 

The [README.md](https://github.com/outscale-dev/osc-bsu-csi-driver) instructions provide the necessary action you need to follow to have the CSI driver up and running. Basically we just run those instructions: 

```
# ENV VARS 
export OSC_ACCESS_KEY=XXXXX
export OSC_SECRET_KEY=XXXXX
export OSC_REGION=eu-west-2
## set the secrets
curl https://raw.githubusercontent.com/outscale-dev/osc-bsu-csi-driver/OSC-MIGRATION/deploy/kubernetes/secret.yaml > secret.yaml
cat secret.yaml | \
    sed "s/secret_key: \"\"/secret_key: \"$OSC_SECRET_KEY\"/g" | \
    sed "s/access_key: \"\"/access_key: \"$OSC_ACCESS_KEY\"/g" > osc-secret.yaml
/usr/local/bin/kubectl delete -f osc-secret.yaml --namespace=kube-system
/usr/local/bin/kubectl apply -f osc-secret.yaml --namespace=kube-system

## deploy the pod
export IMAGE_NAME=outscale/osc-ebs-csi-driver
export IMAGE_TAG="v0.0.9beta"
git clone git@github.com:outscale-dev/osc-bsu-csi-driver.git
cd osc-bsu-csi-driver
helm uninstall osc-bsu-csi-driver  --namespace kube-system
helm install osc-bsu-csi-driver ./osc-bsu-csi-driver \
     --namespace kube-system --set enableVolumeScheduling=true \
     --set enableVolumeResizing=true --set enableVolumeSnapshot=true \
     --set region=$OSC_REGION \
     --set image.repository=$IMAGE_NAME \
     --set image.tag=$IMAGE_TAG
            
## Check the pod is running
kubectl get pods -o wide -A  -n kube-system
```

## create a default storage class 

```
kubectl create -f https://github.com/outscale-dev/osc-bsu-csi-driver/blob/OSC-MIGRATION/examples/kubernetes/dynamic-provisioning/specs/storageclass.yaml
kubectl patch storageclass ebs-sc -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get storageclass
NAME               PROVISIONER       RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
ebs-sc (default)   ebs.csi.aws.com   Delete          WaitForFirstConsumer   false                  7d16h
```


## Enable snapshot features 

Create CRD and the snapshot controller.

```
git clone https://github.com/kubernetes-csi/external-snapshotter.git
cd external-snapshotter
kubectl create -f client/config/crd
code deploy/kubernetes/snapshot-controller
kubectl create -f deploy/kubernetes/snapshot-controller
```

Create a volumesnapshotclass and annotate it for kasten 
```
kubectl create -f https://github.com/outscale-dev/osc-bsu-csi-driver/blob/OSC-MIGRATION/examples/kubernetes/snapshot/specs/classes/snapshotclass.yaml
kubectl annotate volumesnapshotclass csi-aws-vsc k10.kasten.io/is-snapshot-class=true
```

# Install Kasten and demonstrate a backup and restore on a simple application

## Create the kasten-io namespace and add the helm repo 

```
kubectl create ns kasten-io
helm repo add kasten https://charts.kasten.io/
helm repo update 
```

## Precheck 

At this point you should get this output from the precheck script, we removed the warning:

```
curl -s https://docs.kasten.io/tools/k10_primer.sh  | sh /dev/stdin -c "storage csi-checker -s ebs-sc --runAsUser=1000"
Namespace option not provided, using default namespace
Checking for tools
 --> Found kubectl
 --> Found helm
Checking if the Kasten Helm repo is present
 --> The Kasten Helm repo was found
Checking for required Helm version (>= v3.0.0)
 --> No Tiller needed with Helm v3.5.4
K10Primer image
 --> Using Image (gcr.io/kasten-images/k10tools:4.0.2) to run test
Checking access to the Kubernetes context cluster-1
 --> Able to access the default Kubernetes namespace

Running K10Primer Job in cluster with command- 
     ./k10tools primer storage csi-checker -s ebs-sc --runAsUser=1000
serviceaccount/k10-primer created
clusterrolebinding.rbac.authorization.k8s.io/k10-primer created
job.batch/k10primer created
Waiting for pod k10primer-v65jd to be ready - ContainerCreating
Waiting for pod k10primer-v65jd to be ready - ContainerCreating
Waiting for pod k10primer-v65jd to be ready - ContainerCreating
Waiting for pod k10primer-v65jd to be ready - ContainerCreating
Pod Ready!

Starting CSI Checker. Could take up to 5 minutes
Creating application
  -> Created pod (kubestr-csi-original-podnztrk) and pvc (kubestr-csi-original-pvcnsz5t)
  -> Created snapshot (kubestr-snapshot-20210525225623)
Restoring application
  -> Restored pod (kubestr-csi-cloned-pod49kpv) and pvc (kubestr-csi-cloned-pvcpp2mf)
Cleaning up resources
CSI Snapshot Walkthrough:
  Using annotated VolumeSnapshotClass (csi-aws-vsc)
  Successfully tested snapshot restore functionality.  -  OK

serviceaccount "k10-primer" deleted
clusterrolebinding.rbac.authorization.k8s.io "k10-primer" deleted
job.batch "k10primer" deleted
```

## Install kasten and test a backup and restore

Install kasten and wait for all pods to be ready.

```
helm install k10 kasten/k10 -n kasten-io
kubectl get pod -n kasten-io 
NAME                                 READY   STATUS    RESTARTS   AGE
aggregatedapis-svc-b85f954f-5p8bm    1/1     Running   0          7d15h
auth-svc-5754fcfccb-284m5            1/1     Running   0          7d15h
catalog-svc-69d6c5f8bc-ngpjk         2/2     Running   0          7d15h
config-svc-689b56cfd8-jmtmh          1/1     Running   0          7d15h
crypto-svc-7988bcdcb4-sxcwx          1/1     Running   0          7d15h
dashboardbff-svc-56c6c6646d-wndlc    1/1     Running   0          7d15h
executor-svc-b8fc79d7f-hm5gk         2/2     Running   0          7d15h
executor-svc-b8fc79d7f-lcbnw         2/2     Running   0          7d15h
executor-svc-b8fc79d7f-wlr29         2/2     Running   0          7d15h
frontend-svc-7b47b5cb5d-bv8cl        1/1     Running   0          7d15h
gateway-6c7d4fc6d5-zj5dd             1/1     Running   0          5d17h
jobs-svc-79cc56ff4d-997dv            1/1     Running   0          7d15h
kanister-svc-7797d44589-xlrdb        1/1     Running   0          7d15h
logging-svc-79cc4d9689-qkmtn         1/1     Running   0          7d15h
metering-svc-7b9f789857-29j5x        1/1     Running   0          7d15h
prometheus-server-78b94b85fb-qtxjd   2/2     Running   0          7d15h
state-svc-d4f7d56c8-2ssqc            1/1     Running   0          7d15h
```

Now you can [use kasten](https://docs.kasten.io/latest/usage/usage.html) and try some backup and restore.