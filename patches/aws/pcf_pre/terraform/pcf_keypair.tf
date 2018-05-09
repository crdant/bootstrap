variable "key_dir" {
  type = "string"
}

resource "tls_private_key" "pcf_ssh_key" {
  algorithm   = "RSA"
  rsa_bits    = 4096
}

resource "aws_key_pair" "pcf_ssh_key" {
  key_name   = "${var.env_id}-pcf-key"
  public_key =  "${tls_private_key.pcf_ssh_key.public_key_openssh}"
}

resource "local_file" "pcf_private_key" {
  content  = "${tls_private_key.pcf_ssh_key.private_key_pem}"
  filename = "${var.key_dir}/${aws_key_pair.pcf_ssh_key.key_name}.pem"
}

output "pcf_private_key_file" {
  value = "${local_file.pcf_private_key.filename}"
}
