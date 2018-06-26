resource "aws_kms_key" "blobstore_encryption" {
  description             = "Encrypt S3 buckets used for blobstores"
  deletion_window_in_days = 10

  tags {
      Name = "${var.prefix}-blobstore-encryption"
  }
}

resource "aws_s3_bucket" "bosh" {
    bucket = "${var.prefix}-bosh"
    acl = "private"
    force_destroy= true

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = "${aws_kms_key.blobstore_encryption.arn}"
          sse_algorithm     = "aws:kms"
        }
      }
    }

    tags {
        Name = "${var.prefix}-bosh"
        Environment = "${var.prefix}"
    }
}

resource "aws_s3_bucket" "buildpacks" {
    bucket = "${var.prefix}-buildpacks"
    acl = "private"
    force_destroy= true

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = "${aws_kms_key.blobstore_encryption.arn}"
          sse_algorithm     = "aws:kms"
        }
      }
    }

    tags {
        Name = "${var.prefix}-buildpacks"
        Environment = "${var.prefix}"
    }
}

resource "aws_s3_bucket" "droplets" {
    bucket = "${var.prefix}-droplets"
    acl = "private"
    force_destroy= true

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = "${aws_kms_key.blobstore_encryption.arn}"
          sse_algorithm     = "aws:kms"
        }
      }
    }

    tags {
        Name = "${var.prefix}-droplets"
        Environment = "${var.prefix}"
    }
}

resource "aws_s3_bucket" "packages" {
    bucket = "${var.prefix}-packages"
    acl = "private"
    force_destroy= true

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = "${aws_kms_key.blobstore_encryption.arn}"
          sse_algorithm     = "aws:kms"
        }
      }
    }

    tags {
        Name = "${var.prefix}-packages"
        Environment = "${var.prefix}"
    }
}

resource "aws_s3_bucket" "resources" {
    bucket = "${var.prefix}-resources"
    acl = "private"
    force_destroy= true

    server_side_encryption_configuration {
      rule {
        apply_server_side_encryption_by_default {
          kms_master_key_id = "${aws_kms_key.blobstore_encryption.arn}"
          sse_algorithm     = "aws:kms"
        }
      }
    }
    
    tags {
        Name = "${var.prefix}-resources"
        Environment = "${var.prefix}"
    }
}
