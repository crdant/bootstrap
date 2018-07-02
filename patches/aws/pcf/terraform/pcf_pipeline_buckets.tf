resource "aws_s3_bucket" "pipeline_statefile_bucket" {
  bucket = "${var.short_env_id}-terraform-state"
  acl    = "bucket-owner-full-control"
  region = "${var.region}"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "mysql_backup_bucket" {
  bucket = "${var.short_env_id}-mysql-backup-bucket"
  acl    = "bucket-owner-full-control"
  region = "${var.region}"

  versioning {
    enabled = true
  }
}

resource "aws_iam_policy" "pcf-bucket-access" {
  name = "${var.env_id}-pcf-bucket-access"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "PipelineStateBucketPCF",
          "Effect": "Allow",
          "Action":   "*",
          "Resource": "${aws_s3_bucket.pipeline_statefile_bucket.arn}"
      },
      {
          "Sid": "PipelineStateObjectsPCF",
          "Effect": "Allow",
          "Action":   "*",
          "Resource": "${aws_s3_bucket.pipeline_statefile_bucket.arn}/*"
      },
      {
          "Sid": "MySQLBackupBucketPCF",
          "Effect": "Allow",
          "Action":   "*",
          "Resource": "${aws_s3_bucket.mysql_backup_bucket.arn}"
      },
      {
          "Sid": "MySQLBackupObjectsPCF",
          "Effect": "Allow",
          "Action":   "*",
          "Resource": "${aws_s3_bucket.mysql_backup_bucket.arn}/*"
      }
  ]
}
POLICY
}

resource "aws_iam_user_policy_attachment" "pcf-bucket-access" {
    user       = "${aws_iam_user.pcf.name}"
    policy_arn = "${aws_iam_policy.pcf-bucket-access.arn}"
}

resource "aws_iam_policy" "pcf-create-blobstore" {
  name = "${var.env_id}-pcf-create-blobstore"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement":[
     {
        "Sid": "PCFBlobstoreBuckets",
        "Effect":"Allow",
        "Action":[
           "s3:CreateBucket", "s3:ListAllMyBuckets", "s3:GetBucketLocation"
        ],
        "Resource":[
           "arn:aws:s3:::*"
        ]
      }
   ]
}
POLICY
}

resource "aws_iam_user_policy_attachment" "pcf-create-blobstore" {
    user       = "${aws_iam_user.pcf.name}"
    policy_arn = "${aws_iam_policy.pcf-create-blobstore.arn}"
}

output "pipeline_statefile_bucket" {
  value = "${aws_s3_bucket.pipeline_statefile_bucket.id}"
}

output "mysql_backup_bucket" {
  value = "${aws_s3_bucket.mysql_backup_bucket.id}"
}
