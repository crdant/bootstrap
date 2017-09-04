safe_auth_bootstrap () {
  jq --raw-output '.auth.client_token' ${key_dir}/bootstrap-${env_id}-token.json | safe auth token
}
