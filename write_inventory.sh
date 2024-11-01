# This is the previous script.
# The problem here is that the delay needed to wait for the instances to be fully provisioned could be innacurate
# Thereby resulting in the inventory file being empty if too soon. 

# #!/bin/bash

#
# sleep 80  

# # Capture public IPs from Terraform output and write to inventory file
# terraform output -json instance_public_ips | jq -r '.[]' > inventory

# # Check if the output file is populated
# if [ -s inventory ]; then
#   echo "Inventory file created successfully."
#   echo '{"status": "completed"}'
# else
#   echo "Failed to create inventory file."
#   echo '{"status": "failed"}'
# fi


#!/bin/bash

# Function to check if all instances are in the 'running' state
check_instances_running() {
  instance_ids=$(terraform output -json instance_ids | jq -r '.[]')
  running_count=0
  total_count=$(echo "$instance_ids" | wc -l)

  for instance_id in $instance_ids; do
    state=$(aws ec2 describe-instances --instance-ids "$instance_id" --query "Reservations[].Instances[].State.Name" --output text)
    if [ "$state" == "running" ]; then
      ((running_count++))
    fi
  done

  [ "$running_count" -eq "$total_count" ]
}

# Wait for instances to be fully provisioned
max_wait_time=180  # Maximum wait time in seconds
wait_time=0
check_interval=5   # Check every 5 seconds

while ! check_instances_running; do
  if [ "$wait_time" -ge "$max_wait_time" ]; then
    echo "Timed out waiting for instances to be running."
    exit 1
  fi
  sleep "$check_interval"
  wait_time=$((wait_time + check_interval))
done

# Capture public IPs from Terraform output and write to inventory file
terraform output -json instance_public_ips | jq -r '.[]' > inventory

# Check if the output file is populated
if [ -s inventory ]; then
  echo "Inventory file created successfully."
  echo '{"status": "completed"}'
else
  echo "Failed to create inventory file."
  echo '{"status": "failed"}'
fi
