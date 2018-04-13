iam_policy() {
  policy_arn="$(cat ${iam_policy_file} | jq --raw-output '.Policy.Arn' )"
  aws iam delete-policy --policy-arn ${policy_arn}
}

iam_accounts() {
  echo "Deleting IAM account..."
  aws iam detach-user-policy --user-name ${iam_account_name} --policy-arn "$(cat ${workdir}/aws_iam_policy.json | jq --raw-output '.Policy.Arn' )"
  aws iam delete-access-key --user-name ${iam_account_name} --access-key-id $(cat ${key_file} | jq --raw-output '.AccessKey.AccessKeyId')
  aws iam delete-user --user-name ${iam_account_name}
  iam_policy
}

dns () {
  echo "Deleting DNS Zone ${subdomain}..."
  aws route53 delete-hosted-zone --id "$(cat ${dns_zone_file} | jq --raw-output '.HostedZone.Id')"

  # TO DO: put this in here like in https://github.com/crdant/pcf-on-gcp
  # update_root_dns
  # echo "Waiting for ${DNS_TTL} seconds for the Root DNS to sync up..."
  # sleep "${DNS_TTL}"
}
