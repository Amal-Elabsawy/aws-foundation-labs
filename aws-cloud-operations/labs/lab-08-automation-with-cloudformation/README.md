# Lab 08: Automation with CloudFormation

**Type:** Guided lab | **Services:** CloudFormation, VPC, S3, EC2, Systems Manager Parameter Store

## Goal
Describe infrastructure in a template and let CloudFormation build, change and delete it. I deployed a VPC from a template, added an S3 bucket and an EC2 instance by editing the template, and then deleted everything by deleting the stack.

## Proof 
CLI commands and real output in [commands.sh](commands.sh), and step-by-step screenshots in the `screenshots` folder.

## Steps
1. **Read the template:** Opened `task1.yaml` in a text editor and identified its three sections: Parameters (the CIDR ranges for the VPC and subnet), Resources (the VPC, subnet, route table and security group) and Outputs (the default security group of the VPC).
2. **Deployed the stack:** In CloudFormation, created a stack named `Lab` from the template with the default CIDR values. I watched the Events and Resources tabs until the status reached `CREATE_COMPLETE`, then checked that the Lab VPC existed in the VPC console.
3. **Added an S3 bucket:** Added a two-line bucket resource under `Resources` and updated the stack with the changed template. The change preview showed only one addition (the bucket), and the other resources were unchanged. The stack reached `UPDATE_COMPLETE` and the bucket appeared in Resources with a generated name.
4. **Added an EC2 instance:** Added a parameter that looks up the latest Amazon Linux 2 AMI from Parameter Store, then an instance resource that uses `!Ref` to point at the AMI parameter, the app security group and the public subnet. The preview again showed only the new instance, and the `App Server` appeared in Resources and in the EC2 console.
5. **Deleted the stack:** Deleted `Lab`. The status went to `DELETE_IN_PROGRESS`, the stack disappeared after a few minutes, and the VPC, bucket and instance were removed with it.

## Template changes
The bucket (Task 2), under `Resources:`:

```yaml
  AppBucket:
    Type: AWS::S3::Bucket
```

The AMI parameter (Task 3), under `Parameters:`:

```yaml
  AmazonLinuxAMIID:
    Type: AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>
    Default: /aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2
```

The instance (Task 3), under `Resources:`:

```yaml
  AppServer:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: !Ref AmazonLinuxAMIID
      InstanceType: t2.micro
      SecurityGroupIds:
        - !Ref AppSecurityGroup
      SubnetId: !Ref PublicSubnet
      Tags:
        - Key: Name
          Value: App Server
```

## Troubleshooting
Nothing failed in this lab, so I have no incident to report. YAML and references are easy to get wrong, so I checked these before each update:
- **Indentation:** YAML uses two spaces per level, and a wrong indent makes the template invalid.
- **References:** `!Ref` must use the exact logical names already in the template (`AppSecurityGroup`, `PublicSubnet`, `AmazonLinuxAMIID`).
- **List syntax:** `SecurityGroupIds` expects a list, so the value needs a hyphen on its own line.
- **Change preview:** I read the preview before choosing **Update stack** and made sure it only added the new resource and did not replace anything. If an update fails, the Events tab shows which resource caused it.

## Quick reference: parts of a template
| Part | What it does | In this lab |
|---|---|---|
| `Parameters` | Inputs asked for when the stack is created or updated | VPC and subnet CIDR ranges, the AMI lookup |
| `Resources` | The infrastructure to build | VPC, subnet, security group, then the bucket and the instance |
| `Outputs` | Values the stack reports back | The default security group of the VPC |
| `!Ref` | Points at another resource or parameter in the same template | The instance uses the AMI, security group and subnet |
| Change preview | Shows what an update will add, change or replace before it runs | One addition each time |
| Delete stack | Removes everything the stack created | VPC, bucket and instance removed together |

## Reflection
What surprised me is how small the bucket change was: two lines were enough, and CloudFormation worked out the rest and left the other resources alone. Deleting the stack also removed everything it had created, with no leftover resources to hunt for.

In production I would keep templates in Git and review changes before deploying them, so every change to the infrastructure has an author and a history. I would read the change preview carefully for anything marked as a replacement, because that deletes the old resource and creates a new one. For resources that hold data, such as an S3 bucket, I would set a deletion policy so deleting the stack cannot destroy the data, and turn on termination protection on important stacks. I would also move the labs I built by hand, such as the VPC in Lab 04 and the Auto Scaling setup in Lab 03, into templates so they can be rebuilt the same way every time.

