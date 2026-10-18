# Set text styles
YELLOW=$(tput setaf 3)
BOLD=$(tput bold)
RESET=$(tput sgr0)

# Start lab and enter to data required:

echo "Please set the below values correctly"
read -p "${YELLOW}${BOLD}Enter the VM_ZONE: ${RESET}" VM_ZONE
read -p "${YELLOW}${BOLD}Enter the VM_NAME_BASTION (bastion): ${RESET}" VM_NAME_BASTION
read -p "${YELLOW}${BOLD}Enter the tags for task 3: ${RESET}" TAGS_TASK_3
read -p "${YELLOW}${BOLD}Enter the tags for task 4: ${RESET}" TAGS_TASK_4
read -p "${YELLOW}${BOLD}Enter the range ip for bastion host internal range: ${RESET}" INTERNAL_RANGE_BASTION_HOST
read -p "${YELLOW}${BOLD}Enter the tags for task 5: ${RESET}" TAGS_TASK_5
read -p "${YELLOW}${BOLD}Enter the ip internal vm juice-shop: ${RESET}" INTERNAL_IP_JUICE_SHOP


# Export variables after collecting input
export VM_ZONE VM_NAME_BASTION TAGS_TASK_3 TAGS_TASK_4 TAGS_TASK_5 INTERNAL_RANGE_BASTION_HOST INTERNAL_IP_JUICE_SHOP

# Task 1 : Remove the overly permissive rules

gcloud compute firewall-rules delete open-access

# Task 2 : Start the bastion host instance

gcloud compute instances start $VM_NAME_BASTION --zone=$VM_ZONE



# Task 3 : Create a firewall rule that allows SSH (tcp/22) from the IAP service and add network tag on bastion

gcloud compute firewall-rules create ssh-ingress --allow=tcp:22 --source-ranges 35.235.240.0/20 --target-tags $TAGS_TASK_3 --network acme-vpc
gcloud compute instances add-tags bastion --tags=$TAGS_TASK_3 --zone=$VM_ZONE

# Task 4 : Create a firewall rule that allows traffic on HTTP (tcp/80) to any address and add network tag on juice-shop

gcloud compute firewall-rules create http-ingress --allow=tcp:80 --source-ranges 0.0.0.0/0 --target-tags $TAGS_TASK_4 --network acme-vpc
gcloud compute instances add-tags juice-shop --tags=$TAGS_TASK_4 --zone=$VM_ZONE

# Task 5: Create a firewall rule that allows traffic on SSH (tcp/22) from acme-mgmt-subnet network address and add network tag on juice-shop

gcloud compute firewall-rules create internal-ssh-ingress --allow=tcp:22 --source-ranges $INTERNAL_RANGE_BASTION_HOST --target-tags $TAGS_TASK_5 --network acme-vpc
gcloud compute instances add-tags juice-shop --tags=$TAGS_TASK_5 --zone=$VM_ZONE

Task 6 : SSH to bastion host via IAP and juice-shop via bastion

# ssh [Internal IP address of juice-shop]
ssh $INTERNAL_IP_JUICE_SHOP
