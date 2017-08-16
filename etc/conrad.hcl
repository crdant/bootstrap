path "/concourse/*" {
  capabilities = ["create", "read", "update", "list"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
