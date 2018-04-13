iam_accounts () {
  echo "Deleting service accounts..."
  KEYID=`jq --raw-output '.private_key_id' "${key_file}" `
  gcloud projects remove-iam-policy-binding "${project}" --member "serviceAccount:${service_account}" --role "roles/editor" --no-user-output-enabled
  gcloud iam service-accounts --project "${project}" keys delete "${KEYID}" --iam-account "${service_account}" --no-user-output-enabled
  gcloud iam service-accounts --project "${project}" delete "${service_account}" --no-user-output-enabled
}
