# Lab 1: Introduction to AWS IAM

## Objective

Explore existing AWS Identity and Access Management (IAM) users, groups, and policies; assign users to groups; then verify how group permissions control access to Amazon S3 and Amazon EC2.

## Key concepts

- **IAM user:** An identity that can sign in to an AWS account or make AWS requests.
- **IAM group:** A collection of IAM users. Permissions attached to a group apply to its members.
- **Managed policy:** A reusable policy maintained by AWS or an administrator.
- **Inline policy:** A policy embedded directly in one user or group.
- **Least privilege:** Grant only the permissions needed for a role.

An IAM policy commonly includes:
- `Effect`: whether an action is allowed or denied.
- `Action`: the API operations covered by the statement.
- `Resource`: the resources covered by the statement.

## 1. Inspect the existing IAM users

1. Open **IAM** in the AWS Management Console.
2. Select **Users** and inspect `user-1`, `user-2`, and `user-3`.
3. Open `user-1` and review the **Permissions**, **Groups**, and **Security credentials** tabs.
4. Confirm the initial state shown in the lab: `user-1` has no permissions attached directly, belongs to no group, and has a console password.

**Screenshot:** `screenshots/01-iam-users.png`  
*Capture the Users list and/or user-1 details showing the initial configuration.*

## 2. Inspect the existing groups and policies

Open **User groups**, then inspect each group’s **Permissions** tab.

| Group | Policy type | Policy | Intended access |
|---|---|---|---|
| `EC2-Support` | AWS managed | `AmazonEC2ReadOnlyAccess` | View EC2-related information without changing resources |
| `S3-Support` | AWS managed | `AmazonS3ReadOnlyAccess` | List and read S3 resources |
| `EC2-Admin` | Inline | Lab-provided inline policy | View EC2 information and start/stop instances |

Expand each policy to inspect its details, then collapse it when finished.

**Screenshots:**
- `screenshots/02-ec2-support-policy.png` — EC2-Support permissions and policy details.
- `screenshots/03-s3-support-policy.png` — S3-Support permissions and policy details.
- `screenshots/04-ec2-admin-policy.png` — EC2-Admin inline policy details.

## 3. Assign users to groups

Use **User groups** to add each user to the matching group:

1. Open `S3-Support` → **Users** → **Add users**. Select `user-1`, then choose **Add users**.
2. Open `EC2-Support` and add `user-2` in the same way.
3. Open `EC2-Admin` and add `user-3`.
4. Return to **User groups** and verify that each group shows one user.

The intended mapping is:

| IAM user | Group | Expected access |
|---|---|---|
| `user-1` | `S3-Support` | Read-only access to S3 |
| `user-2` | `EC2-Support` | Read-only access to EC2 |
| `user-3` | `EC2-Admin` | View, start, and stop EC2 instances |

**Screenshots:**
- `screenshots/05-user1-added-to-s3-support.png`
- `screenshots/06-user2-added-to-ec2-support.png`
- `screenshots/07-user3-added-to-ec2-admin.png`
- `screenshots/08-group-membership-verification.png`

## 4. Find the IAM sign-in URL

1. Open the IAM **Dashboard**.
2. Find the **Sign-in URL for IAM users in this account**.
3. Copy the URL for use during the tests.

**Important:** Do not publish your account-specific sign-in URL, account identifiers, or lab credentials in this repository. Use only temporary credentials provided by the lab.

**Screenshot:** `screenshots/09-iam-signin-url.png`  
*Before committing the screenshot, blur or crop out account identifiers and the sign-in URL.*

## 5. Test each user’s permissions

Use a private/incognito browser window to test each IAM user separately. Sign out before switching users. Use the temporary username and password shown in your lab environment; do not store passwords in this README.

### Test A: `user-1` — S3 Support

1. Sign in as `user-1`.
2. Open **Amazon S3** and inspect the bucket list and the available bucket contents.
3. Open **Amazon EC2** → **Instances** and check the result.

**Expected result from the lab:** `user-1` can view S3 buckets and their contents, but cannot access EC2 instances because no EC2 permissions have been granted.

**Screenshots:**
- `screenshots/10-user1-s3-access.png`
- `screenshots/11-user1-ec2-denied.png`

### Test B: `user-2` — EC2 Support

1. Sign out as `user-1`.
2. Sign in as `user-2`.
3. Open **Amazon EC2** → **Instances** and select the lab instance named `LabHost`.
4. Try **Instance state** → **Stop instance**. Confirm the action, if prompted, and observe the result.
5. Open **Amazon S3** and check whether the user can list buckets.

**Expected result from the lab:** `user-2` can view EC2 instance information but cannot stop the instance. The user also cannot list S3 buckets.

**Screenshots:**
- `screenshots/12-user2-ec2-read-only.png`
- `screenshots/13-user2-stop-denied.png`
- `screenshots/14-user2-s3-denied.png`

If the EC2 instance is not visible, check that the console is set to the same AWS Region used by the lab.

### Test C: `user-3` — EC2 Admin

1. Sign out as `user-2`.
2. Sign in as `user-3`.
3. Open **Amazon EC2** → **Instances** and select `LabHost`.
4. Choose **Instance state** → **Stop instance**, then confirm **Stop**.
5. Observe the instance state change to `stopping`.

**Expected result from the lab:** `user-3` can stop the EC2 instance under the permissions assigned to `EC2-Admin`.

**Screenshot:** `screenshots/15-user3-stopped-ec2-instance.png`

> **Lab environment note:** AWS Academy/Vocareum environments may restrict some actions. Record the result you actually observe. Do not claim an expected result occurred unless you verified it.

## 6. Results and observations

Complete this section after running the lab. Replace the prompts with your actual observations.

- **IAM group membership:** [Record whether each user was added to the intended group.]
- **S3 permissions:** [Record what `user-1` could access and what `user-2` could not access.]
- **EC2 read-only permissions:** [Record what `user-2` could view and which change operation was denied.]
- **EC2 admin permissions:** [Record whether `user-3` was able to stop `LabHost`.]
- **Technical takeaway:** Group-based permissions let administrators assign access by job function. Read-only access supports visibility without allowing resource changes, while administrative permissions can allow specific actions such as stopping an instance.

## Cleanup and security

- Sign out of the IAM test users and close the private browser window.
- Follow the lab platform’s instructions for ending the lab session.
- Do not commit passwords, access keys, session tokens, unredacted account identifiers, or a private sign-in URL.
- If you include console screenshots, review them for sensitive information before uploading.

## Screenshot checklist

Save screenshots in the `screenshots/` folder beside this README. Use the filenames listed above and replace each placeholder with the matching image using Markdown, for example:

`![IAM users list](screenshots/01-iam-users.png)`

Only mark a screenshot as complete after you have captured and uploaded it.
