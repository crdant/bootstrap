iam_policy() {
  aws_iam_policy="$(cat <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
      {
          "Sid": "VisualEditor0",
          "Effect": "Allow",
          "Action": [
              "logs:*",
              "elasticloadbalancing:*",
              "cloudformation:*",
              "iam:*",
              "kms:*",
              "route53:*",
              "ec2:*"
          ],
          "Resource": "*"
      }
  ]
}
POLICY
)"

  aws iam create-policy --policy-name ${env_id}-policy --policy-document "${aws_iam_policy}" > ${iam_policy_file}
  policy_arn="$(cat ${workdir}/aws_iam_policy.json | jq --raw-output '.Policy.Arn' )"
}

iam_accounts() {
  echo "Configuring IAM account..."
  iam_policy
  aws iam create-user --user-name ${iam_account_name} 2> /dev/null 1> /dev/null
  aws iam create-access-key --user-name ${iam_account_name} > ${key_file}
  aws iam attach-user-policy --user-name ${iam_account_name} --policy-arn ${policy_arn}
}

firewall() {
  # add missing firewall rule to allow jumpbox to tunnel to all BOSH managed vms -- needed for BOSH ssh among other things
  echo "do I still need this"
}

dns () {
  echo "Creating DNS Zone ${subdomain}..."
  aws route53 create-hosted-zone --name ${subdomain} --caller-reference ${env_id}-$(date +"%s") --hosted-zone-config Comment="Zone for ${subdomain} - bbl env ${env_id}" > ${dns_zone_file}

  # TO DO: put this in here like in https://github.com/crdant/pcf-on-gcp
  # update_root_dns
  # echo "Waiting for ${DNS_TTL} seconds for the Root DNS to sync up..."
  # sleep "${DNS_TTL}"
}
