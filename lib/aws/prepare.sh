iam_policy() {
  aws_iam_policy="$(curl -qLs "https://raw.githubusercontent.com/cloudfoundry-incubator/bosh-aws-cpi-release/master/docs/iam-policy.json" | jq '{ "Version": .Version, "Statement": [ .Statement[] | select ( .Sid != "RequiredIfUsingCustomKMSKeys" ) ] }')"
  aws iam create-policy --policy-name ${env_id}-policy --policy-document "${aws_iam_policy}" > ${workdir}/aws_iam_policy.json
  policy_arn="$(cat ${workdir}/aws_iam_policy.json | jq --raw-output '.Policy.Arn' )"
}

iam_accounts() {
  echo "Configuring IAM account..."
  iam_policy
  aws iam create-user --user-name ${iam_account_name} 2> /dev/null 1> /dev/null
  aws iam create-access-key --user-name ${iam_account_name} > ${key_file}
  aws iam attach-user-policy --user-name ${iam_account_name} --policy-arn ${policy_arn}
  access_key_id=$(cat ${key_file} | jq --raw-output '.AccessKey.AccessKeyId')
  secret_access_key=$(cat ${key_file} | jq --raw-output '.AccessKey.SecretAccessKey')
  BBL_AWS_ACCESS_KEY_ID=${access_key_id}
  BBL_AWS_SECRET_ACCESS_KEY=${secret_access_key}
}

firewall() {
  # add missing firewall rule to allow jumpbox to tunnel to all BOSH managed vms -- needed for BOSH ssh among other things
  echo "do I still need this"
}

dns () {
  aws route53 create-hosted-zone ${subdomain} --caller-reference ${env_id}-$(date +"%s") --hosted-zone-config Comment="Zone for ${subdomain} - bbl env ${env_id}"

  # TO DO: put this in here like in https://github.com/crdant/pcf-on-gcp
  # update_root_dns
  # echo "Waiting for ${DNS_TTL} seconds for the Root DNS to sync up..."
  # sleep "${DNS_TTL}"
}
