region="us-west-2"
availability_zone_1="${region}b"
availability_zone_2="${region}c"
availability_zone_3="${region}d"

iam_account_name=`echo ${subdomain} | tr . -`
key_file="${key_dir}/${iam_account_name}-access-key.json"

if [ -f ${key_file} ] ; then
  access_key_id=$(cat ${key_file} | jq --raw-output '.AccessKey.AccessKeyId')
  secret_access_key=$(cat ${key_file} | jq --raw-output '.AccessKey.SecretAccessKey')
else
  access_key_id=${AWS_ACCESS_KEY_ID}
  secret_access_key=${AWS_SECRET_ACCESS_KEY}
fi
