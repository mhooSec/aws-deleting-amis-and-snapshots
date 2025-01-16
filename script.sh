#!/bin/bash

# Global variables
AWS_PROFILE=ec2deploy
REGION="$1"

parameterValidation() {
  # Checking $1 is not empty, as we need to specify a region
  if [ -z "$1" ]; then
    echo "Usage: $0 <region>"
    exit 1
  fi
}

listAMIs() {
  # Describes AMIs within a region
  aws ec2 describe-images \
  --region $REGION \
  --owners self \
  --query 'Images[].{ID:ImageId,Name:Name,Date:CreationDate}' \
  --output table \
  --profile $AWS_PROFILE
}

listSnapshots() {
  echo "Please enter the AMI to delete: "
  read IMAGE_ID

  # Retrieving associated snapshots to an AMI
  SNAPSHOT_IDS=($(
    aws ec2 describe-images \
      --image-ids $IMAGE_ID \
      --query 'Images[].BlockDeviceMappings[].Ebs.SnapshotId' \
      --output text \
      --region $REGION \
      --profile $AWS_PROFILE
  ))

  echo "AMI: $IMAGE_ID uses snapshot(s): ${SNAPSHOT_IDS[@]}"
  echo ""
  echo "Would you like to delete the AMI and the associated snapshots? y/n"
  read DELETE_SELECTOR
  if [[ $DELETE_SELECTOR == "y" ]]; then
    echo "Deleting!"
    deleteAMI "$IMAGE_ID" "$REGION"
    deleteSnapshot "$SNAPSHOT_IDS" "$REGION"
  fi
}

deleteAMI(){
  # Deletes the selected AMI
  aws ec2 deregister-image \
    --image-id $IMAGE_ID \
    --region $REGION \
    --profile $AWS_PROFILE
  echo "Deregistered AMI $IMAGE_ID."
}

deleteSnapshot(){
  # Deletes a list of snapshots
  for SNAP_ID in "${SNAPSHOT_IDS[@]}"; do
    aws ec2 delete-snapshot \
      --snapshot-id "$SNAP_ID" \
      --region $REGION \
      --profile $AWS_PROFILE
    echo "Deleted snapshot $SNAP_ID."
  done
}

parameterValidation $REGION
listAMIs $REGION
listSnapshots $REGION
