iam_accounts() {
  echo "Deleting IAM account..."
  aws iam delete-user --user-name ${iam_account_name}
}
