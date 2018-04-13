iam_policy() {
  policy_arn="$(cat ${workdir}/aws_iam_policy.json | jq --raw-output '.Policy.Arn' )"
  aws iam delete-policy --policy-arn ${policy_arn}
}

iam_accounts() {
  echo "Deleting IAM account..."
  aws iam detach-user-policy --user-name ${iam_account_name} --policy-arn "$(cat ${workdir}/aws_iam_policy.json | jq --raw-output '.Policy.Arn' )"
  aws iam delete-access-key --user-name ${iam_account_name} --access-key-id $(cat ${key_file} | jq --raw-output '.AccessKey.AccessKeyId')
  aws iam delete-user --user-name ${iam_account_name}
  iam_policy
}
