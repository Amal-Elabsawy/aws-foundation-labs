# Lab 1: Introduction to AWS IAM

## Objective

Explore IAM users, groups, and policies; assign users to groups based on their job functions; and verify how permissions affect access to Amazon S3 and Amazon EC2.

## Environment and scenario

The lab provides three IAM users and three groups:

| User | Job function in the scenario | Group | Intended access |
|---|---|---|---|
| `user-1` | S3 support | `S3-Support` | Read-only S3 access |
| `user-2` | EC2 support | `EC2-Support` | Read-only EC2 access |
| `user-3` | EC2 administration | `EC2-Admin` | View, start, and stop EC2 instances |

## 1. Inspect existing IAM users

1. Open **IAM** in the AWS Management Console.
2. Select **Users** and inspect `user-1`, `user-2`, and `user-3`.
3. Open `user-1` and review **Permissions**, **Groups**, and **Security credentials**.
4. Note the initial configuration described by the lab: `user-1` has no permissions attached directly, is not a member of a group, and has a console password.

**Screenshot evidence:** `screenshots/01-iam-users.png`

### Technical observation

IAM users represent identities, but a user does not automatically have broad access to AWS services. Access depends on the permissions granted to that identity, including permissions inherited through group membership. The initial `user-1` configuration provides a baseline for comparing access before and after group assignment.

## 2. Inspect groups and policies

Open **User groups**, then review the **Permissions** tab for each group.

| Group | Policy shown in the lab | What it is intended to allow |
|---|---|---|
| `EC2-Support` | `AmazonEC2ReadOnlyAccess` (AWS managed) | View EC2-related information without changing resources |
| `S3-Support` | `AmazonS3ReadOnlyAccess` (AWS managed) | List and read S3 resources |
| `EC2-Admin` | Inline policy | View EC2 information and start/stop instances |

Expand each policy to inspect its statements, then collapse it when finished.

**Screenshot evidence:**
- `screenshots/02-ec2-support-policy.png`
- `screenshots/03-s3-support-policy.png`
- `screenshots/04-ec2-admin-policy.png`

### Technical observations

- **A policy defines the permission boundary for the actions it covers.** The `Effect` indicates whether a statement allows or denies access, `Action` names the operations, and `Resource` identifies the resources in scope.
- **Read-only access is not administrative access.** A user can be allowed to inspect resources without being allowed to modify or stop them.
- **Managed and inline policies are attached differently.** AWS managed policies can be reused across identities. An inline policy is embedded directly in a particular user or group. The lab uses managed policies for the two support groups and an inline policy for `EC2-Admin`.

## 3. Assign users to groups

1. Open `S3-Support` → **Users** → **Add users**. Select `user-1` and choose **Add users**.
2. Add `user-2` to `EC2-Support`.
3. Add `user-3` to `EC2-Admin`.
4. Return to **User groups** and verify the membership count for each group.

**Screenshot evidence:**
- `screenshots/05-user1-added-to-s3-support.png`
- `screenshots/06-user2-added-to-ec2-support.png`
- `screenshots/07-user3-added-to-ec2-admin.png`
- `screenshots/08-group-membership-verification.png`

### Technical observation

Group-based access makes permission management easier to scale. Rather than configuring the same permissions separately for every person, an administrator can assign users to groups that reflect their responsibilities. This also makes reviews easier: the group and its attached policies provide a clear starting point for checking what access a user should have.

## 4. Locate the IAM user sign-in URL

1. Open the IAM **Dashboard**.
2. Find **Sign-in URL for IAM users in this account**.
3. Keep the URL available for the permission tests.

**Screenshot evidence:** `screenshots/09-iam-signin-url.png`

### Security observation

The sign-in URL is account-specific information. Do not publish the full URL, account identifiers, passwords, access keys, or session tokens in a public repository. Crop or redact them from screenshots before uploading.

## 5. Test permissions by signing in as each user

Use a private/incognito browser window to test each user separately. Sign out before switching users. Use the temporary credentials supplied by the lab; do not put passwords in this repository.

### Test A — `user-1`: S3 support

1. Sign in as `user-1`.
2. Open **Amazon S3** and inspect the bucket list and available bucket contents.
3. Open **Amazon EC2** → **Instances** and check whether access is allowed.

**Expected results described by the lab:** `user-1` can list S3 buckets and browse their contents, but cannot access EC2 instances.

**Screenshot evidence:**
- `screenshots/10-user1-s3-access.png`
- `screenshots/11-user1-ec2-denied.png`

### Technical observation

This test checks both the presence of required access and the absence of unrelated access. The S3 policy gives `user-1` the permissions needed for S3 support, while the user is not intended to receive EC2 access. This illustrates why access should be scoped to a user's responsibilities rather than granting broad access to every AWS service.

### Test B — `user-2`: EC2 support

1. Sign out as `user-1` and sign in as `user-2`.
2. Open **Amazon EC2** → **Instances** and select `LabHost`.
3. Try **Instance state** → **Stop instance** and observe the result.
4. Open **Amazon S3** and check whether the user can list buckets.

**Expected results described by the lab:** `user-2` can view EC2 instance information, cannot stop the instance, and cannot list S3 buckets.

**Screenshot evidence:**
- `screenshots/12-user2-ec2-read-only.png`
- `screenshots/13-user2-stop-denied.png`
- `screenshots/14-user2-s3-denied.png`

If the instance is not visible, check that the AWS console is set to the Region used by the lab.

### Technical observation

The attempted stop operation is a useful negative test: seeing an EC2 instance does not mean the user has permission to change its state. The S3 test also checks service separation. `user-2` is assigned EC2 support permissions, not S3 support permissions. An access-denied response is an expected outcome for an action that the user's permissions do not allow.

### Test C — `user-3`: EC2 administrator

1. Sign out as `user-2` and sign in as `user-3`.
2. Open **Amazon EC2** → **Instances** and select `LabHost`.
3. Choose **Instance state** → **Stop instance**, then confirm **Stop**.
4. Observe whether the instance enters the `stopping` state.

**Expected result described by the lab:** `user-3` has permission to stop the EC2 instance.

**Screenshot evidence:** `screenshots/15-user3-stopped-ec2-instance.png`

### Technical observation

Compared with `user-2`, `user-3` has a broader set of EC2 permissions intended for an administrative role. The difference demonstrates role-based access: support staff can inspect the environment, while an administrator can perform a defined operational action. Administrative access should still be limited to the actions the role actually needs.

> **Evidence rule:** The results above are the expected outcomes from the lab instructions. Replace or supplement them with your own observations after testing. If your result differs, record the actual message and investigate rather than reporting the expected result as if it occurred.

## 6. Results log — complete after running the lab

| Test | What to record | Your actual result |
|---|---|---|
| Group membership | Whether each user appears in the intended group | _Complete after testing_ |
| `user-1` → S3 | Whether buckets and contents are visible | _Complete after testing_ |
| `user-1` → EC2 | Whether access is denied | _Complete after testing_ |
| `user-2` → EC2 | Whether instance information is visible | _Complete after testing_ |
| `user-2` → Stop instance | The exact outcome/message | _Complete after testing_ |
| `user-2` → S3 | Whether bucket listing is denied | _Complete after testing_ |
| `user-3` → Stop instance | Whether the instance enters `stopping` | _Complete after testing_ |

## 7. Overall conclusions

This lab demonstrates that IAM is not only about creating users; it is about matching permissions to responsibilities and validating that the resulting access behaves as intended.

My key takeaways from the lab are:

1. **Use groups to organize access by job function.** This reduces repeated permission configuration and makes access easier to review.
2. **Use least privilege.** Support users should receive only the access needed for their assigned service and tasks.
3. **Test allowed and denied actions.** A good permission check verifies both what a user can do and what the user must not be able to do.
4. **Treat policy inspection and access testing as complementary.** Reading a policy helps explain intended access; signing in as the user confirms the behavior in the lab environment.
5. **Protect account and credential information.** Screenshots are evidence, but they must be checked for sensitive details before publication.

## Cleanup and security

- Sign out of the test users and close the private browser window.
- End the lab using the platform's instructions.
- Never commit passwords, access keys, session tokens, or unredacted account-specific information.
- Review every screenshot before uploading it.

## Screenshot checklist

Save screenshots in the `screenshots/` folder beside this README. When an image is uploaded, embed it using Markdown, for example:

`![IAM users list](screenshots/01-iam-users.png)`

Only treat a screenshot as complete after capturing and uploading the matching image.

