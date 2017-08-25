path "secret/bootstrap/*" {
  capabilities = ["create", "read", "update", "list"]
}

path "auth/token/lookup-self" {
  capabilities = ["read"]
}
