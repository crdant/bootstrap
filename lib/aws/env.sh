stemcell_iaas="aws-xen-hvm"

region="us-west-2"
availability_zone_1="${region}b"
availability_zone_2="${region}c"
availability_zone_3="${region}d"

cloud_config_vars_file=${state_dir}/vars/cloud-config-vars.yml

iam_account_name=`echo ${subdomain} | tr . -`
key_file="${key_dir}/${iam_account_name}-access-key.json"
iam_policy_file="${workdir}/${env_id}-iam-policy.json"
dns_zone_file="${workdir}/${subdomain_token}-dns-zone.json"

if [ -f ${key_file} ] ; then
  access_key_id=$(cat ${key_file} | jq --raw-output '.AccessKey.AccessKeyId')
  secret_access_key=$(cat ${key_file} | jq --raw-output '.AccessKey.SecretAccessKey')
else
  access_key_id=${AWS_ACCESS_KEY_ID}
  secret_access_key=${AWS_SECRET_ACCESS_KEY}
fi

certbot_dns_args="--dns-route53 --dns-route53-propagation-seconds 120"

if [ -f ${dns_zone_file} ]; then
  dns_zone_id="$(cat ${dns_zone_file} | jq --raw-output '.HostedZone.Id')"
fi

if [ -f ${cloud_config_vars_file} ] ; then
  cloud_config_vars="$(sed -e 's/:[^:\/\/]/="/g;s/$/"/g;s/ *=/=/g' ${cloud_config_vars_file} | grep "^vpc_id\|^subnet_id\|^az._subnet\|^internal_security_group")"
  eval "${cloud_config_vars}"
fi
