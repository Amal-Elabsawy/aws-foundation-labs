#!/bin/bash
# Lab 02: commands run on the Bastion Server over SSH (Task 3).
# Paste the real output under each command as a comment before committing.
# Shell variables are lost if the SSH session disconnects, so re-run from the top.

# Get an IMDSv2 token and set the Region from the instance's Availability Zone
TOKEN=$(curl --request PUT "http://169.254.169.254/latest/api/token" --header "X-aws-ec2-metadata-token-ttl-seconds: 21600")
AZ=$(curl --write-out "\n" --request GET "http://169.254.169.254/latest/meta-data/placement/availability-zone" --header "X-aws-ec2-metadata-token: $TOKEN")
export AWS_DEFAULT_REGION=${AZ::-1}

# 1. Latest Amazon Linux AMI ID from Parameter Store
AMI=$(aws ssm get-parameters --names /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2 --query 'Parameters[0].[Value]' --output text)
echo $AMI
# Output:

# 2. Public subnet ID
SUBNET=$(aws ec2 describe-subnets --filters 'Name=tag:Name,Values=Public Subnet' --query Subnets[].SubnetId --output text)
echo $SUBNET
# Output:

# 3. Web security group ID
SG=$(aws ec2 describe-security-groups --filters Name=group-name,Values=WebSecurityGroup --query SecurityGroups[].GroupId --output text)
echo $SG
# Output:

# 4. Download and view the user data script
wget https://aws-tc-largeobjects.s3.amazonaws.com/ILT-TF-200-ACSOPS-1/lab-2-ec2-linux/UserData.txt
cat UserData.txt
# Output:

# 5. Launch the web server instance
INSTANCE=$(\
aws ec2 run-instances \
--image-id $AMI \
--subnet-id $SUBNET \
--security-group-ids $SG \
--user-data file:///home/ec2-user/UserData.txt \
--instance-type t3.micro \
--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Web Server}]' \
--query 'Instances[*].InstanceId' \
--output text \
)
echo $INSTANCE
# Output:

# 6. Check the instance state (repeat until it returns running)
aws ec2 describe-instances --instance-ids $INSTANCE --query 'Reservations[].Instances[].State.Name' --output text
# Output:

# 7. Get the public DNS name and open it in a browser
aws ec2 describe-instances --instance-ids $INSTANCE --query Reservations[].Instances[].PublicDnsName --output text
# Output:

# Challenges (optional): add the commands you used to troubleshoot Misconfigured Web Server below.
