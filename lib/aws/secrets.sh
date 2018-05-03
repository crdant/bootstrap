. ${lib_dir}/aws/dns.sh

vault_load_balancer_name="${short_id}-vault"
vault_security_group_name="${env_id}-vault"

vault_load_balancer_file="${workdir}/${vault_load_balancer_name}-load-balancer.json"
vault_target_group_file="${workdir}/${vault_load_balancer_name}-target-group.json"

if [ -f ${vault_load_balancer_file} ] ; then
  vault_load_balancer_arn="$(cat ${vault_load_balancer_file} | jq --raw-output .LoadBalancers[0].LoadBalancerArn)"
  vault_load_balancer_dns_name="$(cat ${vault_load_balancer_file} | jq --raw-output .LoadBalancers[0].DNSName)"
fi

if [ -f ${vault_target_group_file} ] ; then
  vault_target_group_arn="$(cat ${vault_target_group_file} | jq --raw-output .TargetGroups[0].TargetGroupArn)"
fi

lbs () {
  echo "Creating load balancer..."
  # Create a load balancer
  aws elbv2 create-load-balancer --name ${vault_load_balancer_name} --region ${region} --type network --ip-address-type ipv4 --subnets ${az1_subnet} ${az2_subnet} ${az3_subnet} > ${vault_load_balancer_file}
  vault_load_balancer_arn="$(cat ${vault_load_balancer_file} | jq --raw-output .LoadBalancers[0].LoadBalancerArn)"
  vault_load_balancer_dns_name="$(cat ${vault_load_balancer_file} | jq --raw-output .LoadBalancers[0].DNSName)"

  # Create a target group
  aws elbv2 create-target-group --name ${vault_load_balancer_name}  --region ${region} --protocol TCP --port ${vault_port} --vpc-id ${vpc_id} --target-type ip > ${vault_target_group_file}
  vault_target_group_arn="$(cat ${vault_target_group_file} | jq --raw-output .TargetGroups[0].TargetGroupArn)"

  # Register targets to the target group
  aws elbv2 register-targets --region ${region} --target-group-arn ${vault_target_group_arn} --targets Id=${vault_static_ip},Port=${vault_port}

  # Create one or more listeners for your load balancer using create-listener .
  aws elbv2 create-listener --region ${region} --load-balancer-arn ${vault_load_balancer_arn} --protocol TCP --port ${vault_port} --default-actions Type=forward,TargetGroupArn=${vault_target_group_arn} > /dev/null

  update_cloud_config
}

dns () {
  echo "Configuring DNS..."
  local comment="Vault secret management server"
  set -e
  add_dns_alias "${dns_zone_id}" "${vault_host}" "${load_balanacer_dns_name}" "${comment}"
}

firewall() {
  echo "Adding security group with vault firewall rules..."
  aws create-security-group --description "Access to Vault" --group-name "${vault_security_group_name}" --vpc-id "${vpc_id}"
  aws ec2 authorize-security-group-ingress --group-name ${vault_security_group_name} --protocol tcp --port ${vault_port} --cidr ${vault_access_cidr}
  aws elbv2 set-security-groups --load-balancer-arn ${vault_load_balancer_arn} --security-groups ${vault_security_group_name}
}

teardown_infra() {
  echo "Tearing down supporting infrastructure..."
  aws elbv2 delete-load-balancer --load-balancer-arn ${vault_load_balancer_arn} --region ${region}
  aws elbv2 delete-target-group --target-group-arn ${vault_target_group_arn} --region ${region}
  rm ${vault_load_balancer_file} ${vault_target_group_file}
}
