#!/bin/bash
# Lab 08: the AWS CLI version of what I did in the CloudFormation console.
# The lab itself was done in the console; these commands do the same five steps, so the
# lab role may block some of them. Run them from a terminal that has the AWS CLI
# configured for the lab account (do not change the Region), and paste the real output
# under each command as a comment before committing. Keep only the commands that worked.
# Files: task1.yaml is the downloaded template, task2.yaml is task1.yaml plus the bucket,
# task3.yaml is task2.yaml plus the AMI parameter and the instance.

# --- Task 1: deploy the stack ---

# 1. Check the template is valid
aws cloudformation validate-template --template-body file://task1.yaml
# Output:

# 2. Create the stack named Lab with the default CIDR values, and wait for it
aws cloudformation create-stack --stack-name Lab --template-body file://task1.yaml
aws cloudformation wait stack-create-complete --stack-name Lab
# Output:

# 3. Check the status (expect CREATE_COMPLETE) and the resources it built
aws cloudformation describe-stacks --stack-name Lab --query 'Stacks[0].StackStatus'
aws cloudformation list-stack-resources --stack-name Lab --query 'StackResourceSummaries[].{Logical:LogicalResourceId,Type:ResourceType,Status:ResourceStatus}'
# Output:

# --- Task 2: add the S3 bucket ---

# 4. Preview the change before running it (expect one Add for the bucket)
aws cloudformation create-change-set --stack-name Lab --change-set-name add-bucket --template-body file://task2.yaml
aws cloudformation wait change-set-create-complete --stack-name Lab --change-set-name add-bucket
aws cloudformation describe-change-set --stack-name Lab --change-set-name add-bucket --query 'Changes[].ResourceChange.{Action:Action,Resource:LogicalResourceId,Type:ResourceType}'
# Output:

# 5. Run the change and wait for UPDATE_COMPLETE
aws cloudformation execute-change-set --stack-name Lab --change-set-name add-bucket
aws cloudformation wait stack-update-complete --stack-name Lab
aws cloudformation list-stack-resources --stack-name Lab --query 'StackResourceSummaries[].{Logical:LogicalResourceId,Type:ResourceType,Status:ResourceStatus}'
# Output:

# --- Task 3: add the EC2 instance ---

# 6. Preview the change (expect one Add for the instance)
aws cloudformation create-change-set --stack-name Lab --change-set-name add-instance --template-body file://task3.yaml
aws cloudformation wait change-set-create-complete --stack-name Lab --change-set-name add-instance
aws cloudformation describe-change-set --stack-name Lab --change-set-name add-instance --query 'Changes[].ResourceChange.{Action:Action,Resource:LogicalResourceId,Type:ResourceType}'
# Output:

# 7. Run the change, wait, then check the App Server exists
aws cloudformation execute-change-set --stack-name Lab --change-set-name add-instance
aws cloudformation wait stack-update-complete --stack-name Lab
aws ec2 describe-instances --filters "Name=tag:Name,Values=App Server" --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name,Type:InstanceType}'
# Output:

# 8. The event history of the whole stack (what CloudFormation did, newest first)
aws cloudformation describe-stack-events --stack-name Lab --max-items 10 --query 'StackEvents[].{Time:Timestamp,Resource:LogicalResourceId,Status:ResourceStatus}'
# Output:

# --- Task 4: delete the stack ---

# 9. Delete the stack and wait; CloudFormation removes the VPC, bucket and instance with it
aws cloudformation delete-stack --stack-name Lab
aws cloudformation wait stack-delete-complete --stack-name Lab
# Output:

# 10. Confirm it is gone (this should fail with "Stack with id Lab does not exist")
aws cloudformation describe-stacks --stack-name Lab
# Output:

