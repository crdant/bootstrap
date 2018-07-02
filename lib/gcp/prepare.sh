pre_plan () {
  if [ ! -f "${key_file}" ] && [ ! -f "${plan_key_file}" ] ; then
    # create an account for preparing the environment
    gcloud iam service-accounts create ${plan_service_account_name} --display-name "Baseline service account to run \`bbl plan\`" --no-user-output-enabled
    gcloud iam service-accounts keys create --iam-account="${plan_service_account}" ${plan_key_file} --no-user-output-enabled
    . ${lib_dir}/${iaas}/bbl_env.sh
    gcloud projects add-iam-policy-binding ${project} --member="serviceAccount:${plan_service_account}" --role="roles/owner" --no-user-output-enabled
  fi
}

post_director () {
  if [ -f "${key_file}" ] && [ -f "${plan_key_file}" ] ; then
    # delete the temporary account
    gcloud iam service-accounts keys delete --iam-account="${plan_service_account}" ${key_file} --no-user-output-enabled
    gcloud iam service-accounts delete ${plan_service_account_name} --no-user-output-enabled
    rm ${plan_key_file}
  fi
}
