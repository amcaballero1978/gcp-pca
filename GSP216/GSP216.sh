# Set text styles
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
RESET=$(tput sgr0)

echo "Please set the below values correctly"
read -p "${YELLOW}${BOLD}Enter the REGION1: ${RESET}" REGION1
read -p "${YELLOW}${BOLD}Enter the REGION2: ${RESET}" REGION2
read -p "${YELLOW}${BOLD}Enter the VM_ZONE: ${RESET}" REGION

# Export variables after collecting input
export REGION1 REGION2 REGION

# Create firewall rules:

gcloud compute firewall-rules create app-allow-http \
--network=my-internal-app \
--direction=INGRESS \
--action=ALLOW \
--target-tags=lb-backend \
--source-ranges=10.10.0.0/16 \
--rules=tcp:80

gcloud compute firewall-rules create app-allow-health-check \
--network=my-internal-app \
--action allow \
--direction INGRESS \
--target-tags lb-backend \
--source-ranges 130.211.0.0/22,35.191.0.0/16 \
--rules tcp

# Create instance templates:

gcloud compute instance-templates create instance-template-1 \
--machine-type=e2-micro \
--network=my-internal-app \
--region=$REGION \
--subnet=subnet-a \
--no-address \
--tags=lb-backend \
--metadata=startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh

gcloud compute instance-templates create instance-template-2 \
--machine-type=e2-micro \
--network=my-internal-app \
--region=$REGION \
--subnet=subnet-b \
--no-address \
--tags=lb-backend \
--metadata=startup-script-url=gs://cloud-training/gcpnet/ilb/startup.sh

# Create instance groups:

gcloud compute instance-groups managed create instance-group-1 \
--base-instance-name=instance-group-1 \
--template=instance-template-1 \
--zone=$REGION1 \
--size=1

gcloud compute instance-groups managed set-autoscaling instance-group-1 \
--zone=$REGION1 \
--cool-down-period=45 \
--max-num-replicas=1 \
--min-num-replicas=1 \
--target-cpu-utilization=0.8

gcloud compute instance-groups managed create instance-group-2 \
--base-instance-name=instance-group-2 \
--template=instance-template-2 \
--zone=$REGION2 \
--size=1

gcloud compute instance-groups managed set-autoscaling instance-group-2 \
--zone=$REGION2 \
--cool-down-period=45 \
--max-num-replicas=1 \
--min-num-replicas=1 \
--target-cpu-utilization=0.8

# Create vm utility-vm

gcloud compute instances create utility-vm \
--zone=$REGION1 \
--machine-type=e2-micro \
--image-family=debian-13 \
--image-project=debian-cloud \
--boot-disk-size=10GB \
--boot-disk-type=pd-standard \
--network=my-internal-app \
--subnet=subnet-a \
--no-address \
--private-network-ip=10.10.20.50  


# Create LB

gcloud compute health-checks create tcp my-ilb-health-check \
--description="subscribe to techcps" \
--check-interval=5s \
--timeout=5s \
--unhealthy-threshold=2 \
--healthy-threshold=2 \
--port=80 \
--proxy-header=NONE

TOKEN=$(gcloud auth application-default print-access-token)

cat > cp1.json <<EOF_END
{
    "backends": [
      {
        "balancingMode": "CONNECTION",
        "group": "projects/$DEVSHELL_PROJECT_ID/zones/$REGION1/instanceGroups/instance-group-1"
      },
      {
        "balancingMode": "CONNECTION",
        "group": "projects/$DEVSHELL_PROJECT_ID/zones/$REGION2/instanceGroups/instance-group-2"
      }
    ],
    "connectionDraining": {
      "drainingTimeoutSec": 300
    },
    "description": "",
    "healthChecks": [
      "projects/$DEVSHELL_PROJECT_ID/global/healthChecks/my-ilb-health-check"
    ],
    "loadBalancingScheme": "INTERNAL",
    "logConfig": {
      "enable": false
    },
    "name": "my-ilb",
    "network": "projects/$DEVSHELL_PROJECT_ID/global/networks/my-internal-app",
    "protocol": "TCP",
    "region": "projects/$DEVSHELL_PROJECT_ID/regions/$REGION",
    "sessionAffinity": "NONE"
  }
EOF_END

cat > cp2.json <<EOF_END
{
   "IPAddress": "10.10.30.5",
   "loadBalancingScheme": "INTERNAL",
   "allowGlobalAccess": false,
   "description": "subscribe to techcps",
   "ipVersion": "IPV4",
   "backendService": "projects/$DEVSHELL_PROJECT_ID/regions/$REGION/backendServices/my-ilb",
   "IPProtocol": "TCP",
   "networkTier": "PREMIUM",
   "name": "my-ilb-forwarding-rule",
   "ports": [
     "80"
   ],
   "region": "projects/$DEVSHELL_PROJECT_ID/regions/$REGION",
   "subnetwork": "projects/$DEVSHELL_PROJECT_ID/regions/$REGION/subnetworks/subnet-b"
 }
EOF_END

curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d  @cp1.json \
"https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/backendServices"

sleep 17

curl -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $TOKEN" -d @cp2.json \
"https://compute.googleapis.com/compute/v1/projects/$DEVSHELL_PROJECT_ID/regions/$REGION/forwardingRules"