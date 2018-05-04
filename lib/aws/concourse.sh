dns() {
  echo "Setting up DNS..."
  local hostname="$(bbl lbs | grep "^Concourse LB:" | grep -o '\[.*\]' | tr -d [ | tr -d ])"
  add_dns_alias ${dns_zone_id} ${concourse_host} ${hostname} "Bootstrap concourse for ${env_id}"
}
