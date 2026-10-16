#!/bin/bash
# Lab 05: Managing Storage. Every command from the lab, in order.
#
# Windows note: I connected with PuTTY and labsuser.ppk, so there is no chmod or "ssh -i" step.
# Every command below was typed in the PuTTY window, which is a Linux shell on the instance.
# The S3 bucket and the IAM role (S3BucketAccess on the Processor) were done in the console.
# "# Expected:" is what the lab says the result looks like. Replace it with the real output
# from your PuTTY window if you want to show it (select the text in PuTTY, copy, paste here).
#
# Part A runs on the Command Host. Part B (the challenge) runs on the Processor instance.

# 0. Connect to the Command Host (Windows, PuTTY)
#    - EC2 console > Command Host > copy the Public IPv4 address
#    - Lab "Details" > Show > Download PPK (labsuser.ppk)
#    - PuTTY > Connection > Seconds between keepalives = 30
#    - PuTTY > Session > Host Name = the Public IPv4 address
#    - PuTTY > Connection > SSH > Auth > Credentials > Private key file = labsuser.ppk
#    - Open > Accept > login as: ec2-user
#    (PowerShell alternative: ssh -i labsuser.pem ec2-user@PUBLIC_IP, using the downloaded PEM)

# Values from my lab. Replace each one with what the lab showed me, as I get it below:
BUCKET="S3-BUCKET-NAME"        # the bucket name I created in S3
INSTANCE_ID="INSTANCE-ID"      # from command 3
VOLUME_ID="VOLUME-ID"          # from command 2
SNAPSHOT_ID="SNAPSHOT-ID"      # from command 5
VERSION_ID="VERSION-ID"        # from command 21

# ===== Part A: snapshots (on the Command Host) =====

# 1. Full description of the Processor instance
aws ec2 describe-instances --filter 'Name=tag:Name,Values=Processor'
# Expected: a long JSON description of the instance and all of its attributes.

# 2. Only the root volume ID
aws ec2 describe-instances --filter 'Name=tag:Name,Values=Processor' --query 'Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.{VolumeId:VolumeId}'
# Expected: { "VolumeId": "vol-..." }

# 3. The instance ID
aws ec2 describe-instances --filters 'Name=tag:Name,Values=Processor' --query 'Reservations[0].Instances[0].InstanceId'
# Expected: "i-..."

# 4. Stop the Processor (so the snapshot is consistent) and wait until it has stopped
aws ec2 stop-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-stopped --instance-id $INSTANCE_ID
# Expected: stop-instances shows the state going to "stopping"; the wait returns to the prompt when stopped.

# 5. Take the first snapshot of the root volume
aws ec2 create-snapshot --volume-id $VOLUME_ID
# Expected: JSON that includes a "SnapshotId": "snap-..." and "State": "pending".

# 6. Wait until the snapshot is completed
aws ec2 wait snapshot-completed --snapshot-id $SNAPSHOT_ID
# Expected: returns to the prompt when the snapshot is complete.

# 7. Start the Processor again and wait until it is running
aws ec2 start-instances --instance-ids $INSTANCE_ID
aws ec2 wait instance-running --instance-id $INSTANCE_ID
# Expected: start-instances shows "pending"; the wait returns to the prompt when running.

# 8. Create the cron job file: take a snapshot every minute (lab only, to see results quickly)
echo "* * * * *  aws ec2 create-snapshot --volume-id $VOLUME_ID >> /tmp/cronlog 2>&1" > cronjob
# Expected: no output.

# 9. Schedule it (takes 1 to 2 minutes before the first snapshot appears)
crontab cronjob
# Expected: no output.

# 10. Check that new snapshots are being created (run it again after a few minutes)
aws ec2 describe-snapshots --filters "Name=volume-id,Values=$VOLUME_ID"
# Expected: JSON listing one or more snapshots of the volume, growing over time.

# 11. Stop the cron job
crontab -r
# Expected: no output.

# 12. Read the cleanup script
more snapshotter_v2.py
# Expected: a short Python (Boto3) script that keeps only the two newest snapshots per volume.

# 13. List the snapshot IDs before cleanup
aws ec2 describe-snapshots --filters "Name=volume-id,Values=$VOLUME_ID" --query 'Snapshots[*].SnapshotId'
# Expected: several snapshot IDs, the ones created by the cron job.

# 14. Run the cleanup script
python3.11 snapshotter_v2.py
# Expected: "Deleting snapshot snap-..." for every snapshot except the two newest.

# 15. List the snapshot IDs after cleanup
aws ec2 describe-snapshots --filters "Name=volume-id,Values=$VOLUME_ID" --query 'Snapshots[*].SnapshotId'
# Expected: only two snapshot IDs.

# 16. Close the Command Host session
exit

# ===== Part B: challenge, S3 sync and versioning (on the Processor instance) =====
# Connect to the Processor the same way (PuTTY, labsuser.ppk, user ec2-user). Use its Public IPv4
# address from the EC2 console now, because it can change after the stop and start in step 4.

# 17. Download and unzip the sample files (a "files" folder with file1.txt, file2.txt, file3.txt)
wget https://aws-tc-largeobjects.s3-us-west-2.amazonaws.com/CUR-TF-200-RESOPS/lab5vocareum/files.zip
unzip files.zip
# Expected: files.zip is downloaded and unzipped into the files folder.

# 18. Turn on versioning for the bucket
aws s3api put-bucket-versioning --bucket $BUCKET --versioning-configuration Status=Enabled
# Expected: no output.

# 19. Sync the folder to S3, then list it
aws s3 sync files s3://$BUCKET/files/
aws s3 ls s3://$BUCKET/files/
# Expected: sync prints "upload: files/file1.txt to s3://..." for all three files; ls lists the three files.

# 20. Delete a file locally, sync with --delete, then list again
rm files/file1.txt
aws s3 sync files s3://$BUCKET/files/ --delete
aws s3 ls s3://$BUCKET/files/
# Expected: "delete: s3://.../files/file1.txt". Some CLI versions also print
# "'str' object has no attribute 'text'", which is harmless; ls then shows only the other two files.

# 21. List the versions of the deleted file (copy the VersionId from the Versions block)
aws s3api list-object-versions --bucket $BUCKET --prefix files/file1.txt
# Expected: a DeleteMarkers block and a Versions block with one entry and its VersionId.

# 22. Download the old version, check it is back locally
aws s3api get-object --bucket $BUCKET --key files/file1.txt --version-id $VERSION_ID files/file1.txt
ls files
# Expected: get-object prints the object details; ls shows file1.txt, file2.txt and file3.txt.

# 23. Sync again to put the restored file back in S3, then list
aws s3 sync files s3://$BUCKET/files/
aws s3 ls s3://$BUCKET/files/
# Expected: "upload: files/file1.txt to s3://..." and ls lists all three files, with a new version of file1.txt.
