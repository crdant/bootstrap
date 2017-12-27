safe_auth_bootstrap () {
  jq --raw-output '.auth.client_token' ${key_dir}/bootstrap-${env_id}-token.json | safe auth token
}

bootstrap_secret () {
  local component=${1}
  local secret=${2}
  safe get secret/bootstrap/${component}/${secret}:value
}

credhub_auth () {
  https_proxy=$BOSH_ALL_PROXY credhub login -s https://10.0.0.6:8844 -u credhub-cli -p $(bosh int --path /credhub_cli_password ${state_dir}/vars/director-vars-store.yml ) \
    --ca-cert <(cat <(bosh int --path /default_ca/ca ${state_dir}/vars/director-vars-store.yml) <(bosh int --path /credhub_ca/ca ${state_dir}/vars/director-vars-store.yml))
}

bosh_secret () {
  https_proxy=$BOSH_ALL_PROXY credhub $@
}
