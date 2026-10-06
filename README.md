# hashicorp-vault-ansible

Ansible playbooks that set up HashiCorp Vault on Debian hosts, as two 3-node Raft clusters, each behind an HAProxy load balancer that routes to the active node only:

- **foundation-vault**: unsealed by people holding unseal keys.
- **workload-vault**: unsealed by a seal beside each node that answers Vault's transit API.

The playbooks install and configure. They never initialize, unseal or restart Vault: the ceremonies are run with [vault-ceremony](https://github.com/zinrai/vault-ceremony), and restarting a node is the operator's call, since a restarted foundation-vault node stays sealed until its holders unseal it. A changed configuration or certificate is applied by reloading Vault; what Vault reads only at start, such as the seal or the storage, waits for the next restart.

The same hierarchy runs on Docker Compose in [hashicorp-vault-sandbox](https://github.com/zinrai/hashicorp-vault-sandbox).

## Requirements

- A control machine with Ansible
- Debian 13 hosts that Ansible reaches over SSH as root or with sudo, with swap disabled and the clock kept by NTP
- Vault's 8200 reachable from the load balancer and from the machines vault-ceremony runs on, and 8201 between nodes; the load balancer's 8200 from applications and operators
- For each node, a TLS certificate from your offline CA for the node's IP and the load balancer's, and its key

## Usage

Each cluster has its own directory under `ansible/`, with its inventory. Put each host's address in `inventory`, and what your CA issued where the host will have it, under the host's name:

```
ansible/standard/roles/vault_conf/files/<node>/etc/vault.d/tls/server.crt
ansible/standard/roles/vault_conf/files/<node>/etc/vault.d/tls/server.key
ansible/standard/roles/vault_conf/files/<node>/etc/vault.d/tls/ca.crt
ansible/standard/roles/haproxy_conf/files/<load balancer>/etc/haproxy/vault-ca.crt
```

For workload-vault, also the seal's key:

```
ansible/standard/roles/vault-seal-dev_conf/files/<node>/etc/vault-seal-dev/key.gpg
```

These are gitignored. Then:

```bash
$ cd ansible/foundation-vault && ansible-playbook foundation-vault.yml
$ cd ansible/workload-vault && ansible-playbook workload-vault.yml
```

and initialize each cluster with vault-ceremony, with the nodes' IPs in its `ceremony.yaml`.

[vault-seal-dev](https://github.com/zinrai/vault-seal-dev) keeps its key in a file on every node, so it is for development only. A seal backed by a KMS is not here yet.

To try the playbooks on LXC containers on one host, see [docs/lxc.md](docs/lxc.md).

## Operations

Each change is made in the repository and applied by running the cluster's playbook again.

**Configuration**: change the inventory, the cluster's file in `ansible/standard/group_vars/`, or a certificate.

**Break-glass**: when nobody can log in to start a root token generation, change `enable_unauthenticated_access` to `[generate-root]` in the cluster's `group_vars` file and run the playbook. Generate the root token with vault-ceremony, then set it back to `[]` and run the playbook again.

**Restarting**: one node at a time, the standbys first and the active node last, waiting for each to be unsealed before the next. A workload-vault node unseals itself; a foundation-vault node comes back sealed, and `vault-ceremony status` shows its holders what to run.

**Upgrading**: change `vault.version` in `ansible/standard/roles/vault/defaults/main.yml` and run the playbook. Each node keeps running the old version until it is restarted as above. Read HashiCorp's [upgrade guide](https://developer.hashicorp.com/vault/docs/upgrading) for the versions in between first.

## License

This project is licensed under the [MIT License](./LICENSE).
