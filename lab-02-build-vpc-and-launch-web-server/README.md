# Lab 2: Build a VPC and Launch a Web Server

**Type:** Guided lab | **Region:** us-east-1 | **Services:** VPC, EC2, Security Groups, NAT Gateway, Internet Gateway

## Goal
Build a custom network from scratch (public and private subnets across two Availability Zones) and launch a web server inside it that is reachable from the internet.

## Architecture
| Resource | Value |
|---|---|
| VPC | `lab-vpc` (10.0.0.0/16) |
| Public subnets | 10.0.0.0/24 (AZ a), 10.0.2.0/24 (AZ b) |
| Private subnets | 10.0.1.0/24 (AZ a), 10.0.3.0/24 (AZ b) |
| Gateways | 1 Internet Gateway, 1 NAT Gateway |
| Security group | `Web Security Group` (inbound HTTP 80 from anywhere) |
| Instance | `Web Server 1`, t2.micro, Amazon Linux 2023, in the public subnet |

## Steps
1. Created the VPC with the "VPC and more" wizard: one public and one private subnet, an Internet Gateway, a NAT Gateway, and a route table for each subnet type.
2. Added a second public subnet and a second private subnet in another Availability Zone, for high availability.
3. Associated the new private subnet with the private route table (default route to the NAT Gateway) and the new public subnet with the public route table (default route to the Internet Gateway).
4. Created a security group in `lab-vpc` that allows inbound HTTP from anywhere.
5. Launched an EC2 instance in the public subnet with a public IP and the security group attached.
6. Used a user data script to install Apache and PHP and deploy the sample web app on first boot.
7. Waited for 2/2 status checks, then opened the instance's public DNS in a browser.

## Verification
- The web page loaded from the instance's public DNS and showed the instance metadata.
- The instance reached 2/2 status checks.
- The lab submission scored full marks.
- CLI checks (outputs saved in `commands.sh` comments): see [commands.sh](commands.sh)

## Troubleshooting
> TODO: Write one real issue you hit and how you fixed it (wrong subnet, page not loading, status check delay, etc.). If nothing went wrong, write what you checked when the page did not load right away, and why.

## What I learned
- A subnet is "public" because its route table sends 0.0.0.0/0 to an Internet Gateway, not because of its name.
- Private subnets reach the internet through a NAT Gateway, which sits in a public subnet.
- Security groups are stateful firewalls attached to the instance.

## Reflection / how I would do this in production
> TODO: 2-3 lines in your own words. Ideas to react to:
> - Restrict HTTP to a load balancer instead of `0.0.0.0/0`, and put the web server in a private subnet behind an ALB.
> - Use one NAT Gateway per AZ for resilience (cost vs availability trade-off).
> - Use HTTPS and manage access with Systems Manager Session Manager instead of SSH keys.
> - Define the whole network as code (Terraform or CloudFormation).
