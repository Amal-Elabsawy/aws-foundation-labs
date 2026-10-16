#!/bin/bash
# Lab 04: commands from the optional test (private subnet).
# The VPC, subnets, gateways, route tables and instances were created in the console.
# Run these in order, and paste the real output under each command as a comment before committing.

# --- On your own computer (Windows users did this step in PuTTY with labsuser.ppk) ---

# 1. Connect to the Bastion Server (use its Public IPv4 address)
chmod 400 labsuser.pem
ssh -i labsuser.pem ec2-user@BASTION_PUBLIC_IP
# Output:

# --- Now on the Bastion Server (public subnet) ---

# 2. Show the bastion's own address (should be 10.0.0.x, in the Public Subnet)
hostname -I
# Output:

# 3. Jump to the Private Instance using its Private IPv4 address (10.0.2.x or 10.0.3.x)
ssh PRIVATE_INSTANCE_IP
# Output:

# --- Now on the Private Instance (private subnet) ---

# 4. Show its address (should be 10.0.2.x or 10.0.3.x, in the Private Subnet)
hostname -I
# Output:

# 5. Prove it can reach the internet outbound, through the NAT Gateway
ping -c 3 amazon.com
# Output:

# 6. Extra proof: the public IP the internet sees should be the NAT Gateway's Elastic IP
curl -s https://checkip.amazonaws.com
# Output:
# (Compare it with the Elastic IP of the NAT Gateway in the VPC console.)
