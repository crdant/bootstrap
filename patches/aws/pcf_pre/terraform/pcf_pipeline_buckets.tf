resource "aws_s3_bucket" "pipeline_statefile_bucket" {
  bucket = "${var.short_env_id}-statefile-bucket"
  acl    = "bucket-owner-full-control"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket" "mysql_backup_bucket" {
  bucket = "${var.short_env_id}-mysql-backup-bucket"
  acl    = "bucket-owner-full-control"

  versioning {
    enabled = true
  }
}

output "pipeline_statefile_bucket" {
  value = "${aws_s3_bucket.pipeline_statefile_bucket.id}"
}

output "mysql_backup_bucket" {
  value = "${aws_s3_bucket.mysql_backup_bucket.id}"
}
