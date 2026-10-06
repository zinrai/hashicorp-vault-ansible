# Not narrower: operators run the Foundation Vault. Whoever can write
# policies can grant themselves anything, so it is root in all but name. The
# denials below stop mistakes, not a determined operator: changing an audit
# device, and the two steps that would lock every operator out.

path "sys/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Not writable: adding or removing an audit device takes a generated root
# token (vault-ceremony generate-root, then vault audit with that token).
path "sys/audit" {
  capabilities = ["read", "sudo"]
}

path "sys/audit/*" {
  capabilities = ["read"]
}

# Not writable: disabling userpass, or changing this policy, would leave no
# operator able to log in with admin rights, and no token to generate a root
# token with. Like an audit device, it takes a generated root token.
path "sys/auth/userpass" {
  capabilities = ["read", "sudo"]
}

path "sys/policy/admin" {
  capabilities = ["read"]
}

path "sys/policies/acl/admin" {
  capabilities = ["read"]
}

path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "identity/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}

path "secret/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
