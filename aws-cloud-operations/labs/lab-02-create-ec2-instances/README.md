# Lab 02: Creating Amazon EC2 Instances

**Type:** Guided lab with optional troubleshooting challenges | **Services:** EC2, AWS CLI, Systems Manager Parameter Store, IAM instance profile, VPC, Security Groups

## Goal
Launch EC2 instances two ways, from the console and from the AWS CLI, and compare them. The console instance is a bastion server used to run the CLI commands that launch a web server.


## Proof 
CLI commands and real output in [commands.sh](commands.sh), and step-by-step screenshots in the `screenshots` folder.

## Steps
1. **Launched the bastion from the console:** Created `Bastion Server` in the lab VPC's public subnet with a public IP, a new security group that allows SSH, the lab key pair, and the `Bastion-Role` IAM instance profile so the instance can call AWS APIs. Waited for Running and 2/2 status checks.
2. **Connected over SSH:** Logged in to the bastion as `ec2-user` with the lab key pair.
3. **Collected the launch values with the CLI:** From the bastion, looked up the latest Amazon Linux AMI ID in Parameter Store, then the public subnet ID, the web security group ID, and downloaded the user data script that installs the web app.
4. **Launched the web server with the CLI:** Ran `aws ec2 run-instances` with those values and a `Name=Web Server` tag, then checked the instance state with `describe-instances` until it was running.
5. **Tested it:** Got the instance's public DNS with a CLI query, opened it in the browser and the web page loaded. Both instances were also visible in the console.

## Challenges (optional)

### Challenge 1: Connect to an Amazon EC2 Instance (solved)
- **Problem:** I could not SSH into `Misconfigured Web Server`. PuTTY failed with `Network error: Connection timed out`. The instance was healthy (Running, 2/2 checks passed) and had a public IP, so the key was not the problem.
- **How I found it:** A timeout means traffic on port 22 never reached the instance (a wrong key would have been rejected after connecting), so I checked the instance's security group inbound rules and found it did not allow SSH (port 22).
- **Fix:** I added an inbound rule for SSH (port 22) to the security group and reconnected.
- **Proof:** After the fix, PuTTY connected as `ec2-user`. Commands run on the instance returned the same instance ID and IP as the console (see [commands.sh](commands.sh)).

### Challenge 2: Fix the Web Server Installation (not fully resolved)
- **Problem:** The website on `Misconfigured Web Server` could not be reached through the instance's public IP. Apache (`httpd`) was inactive, so nothing answered HTTP requests.
- **What I did:**
  1. Checked Apache with `sudo systemctl is-active httpd`.
  2. Started it with `sudo systemctl start httpd`.
  3. Confirmed Apache was active and listening on port 80 with `sudo ss -lntp | grep ':80'`.
  4. Checked that the local firewall was inactive.
  5. Checked that the security group allows inbound TCP on port 80.
  6. Checked the subnet's route table and found an active default route to the Internet Gateway.
  7. Checked the network ACL and confirmed inbound traffic was allowed.
  8. Retried the public IP, but the website was still not reachable.
- **Result:** Not fully resolved. I started the stopped service and ruled out the local firewall, the security group, the route table and the inbound network ACL.
- **What I would check next:** the network ACL's outbound rules (network ACLs are stateless, so return traffic needs its own rule), `curl -I http://localhost` on the instance to separate a web server problem from a network problem, and whether Apache listens on all addresses and not only on 127.0.0.1.

## Troubleshooting
When a connection to an instance failed, I worked from the outside in: is the instance running and does it have a public IP, then the security group, the route table, the network ACL, the operating system firewall, and finally the service itself.

**SSH timed out on Misconfigured Web Server (solved)**
- **Symptom:** PuTTY showed `Network error: Connection timed out`, while the console showed the instance as Running with 2/2 checks.
- **Reasoning:** A timeout means packets are dropped on the way, so the key and the user name were not the problem. The instance had a public IP, so the security group was the next place to look.
- **Cause and fix:** The security group did not allow SSH (port 22). I added an inbound rule for port 22 and the connection worked.

**Website unreachable on Misconfigured Web Server (not fully resolved)**
- **Symptom:** The website did not load on the instance's public IP.
- **Found:** Apache (`httpd`) was inactive. I started it and confirmed it was listening on port 80.
- **Ruled out:** the local firewall (inactive), the security group (port 80 allowed), the route table (default route to the Internet Gateway) and the network ACL's inbound rules.
- **Still open:** the site stayed unreachable. Next I would check the network ACL's outbound rules and run `curl -I http://localhost` on the instance to see whether the problem is the web server or the network.

## Quick reference: what each connection error means
I hit the first error below in Challenge 1. The others are what I would expect from the other layers.

| What I saw | What it means | Where to look first |
|---|---|---|
| `Connection timed out` | Packets are dropped before they reach the service | Security group, route table, network ACL, public IP |
| `Connection refused` | The instance answered, but nothing listens on that port | Is the service running, and on which port and address |
| `Permission denied (publickey)` | SSH was reached, but the key or user was rejected | Key pair, user name (`ec2-user`), key file |
| Web page with an error such as 403 or 404 | The web server is running and answering | Web root content and file permissions |

## Reflection
The most useful part of this lab was the two challenges, because they showed that a healthy instance can still be unreachable. In Challenge 1 nothing was wrong with the server: a single missing port 22 rule was enough to cause a timeout. In Challenge 2 I checked five layers and still could not load the page, which showed me that I should split the problem sooner, by testing from inside the instance before changing network settings.

In production I would not leave SSH open to the internet. I would restrict it to my own IP, or remove it and use Session Manager as in Lab 01. I would also put the launch steps in a CloudFormation template (see Lab 08), so a launch does not depend on me remembering every setting, and I would require IMDSv2 on instances.

