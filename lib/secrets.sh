safe_auth_bootstrap () {
  jq --raw-output '.auth.client_token' ${key_dir}/bootstrap-${env_id}-token.json | safe auth token
}

bootstrap_secret () {
  local component=${1}
  local secret=${2}
  safe get secret/bootstrap/${component}/${secret}:value
}
