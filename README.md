# Infrastructure (Salt Bootstrap)

Helper repository to bootstrap Salt masters and minions.

## Bootstrapping the Salt master

Use this `cloud-init` script:

```yaml
#cloud-config

package_update: true
package_upgrade: true

packages:
  - git
  - curl

runcmd:
  - curl -fsSL https://raw.githubusercontent.com/tristankretzer/infra-salt-bootstrap/refs/heads/master/bootstrap-master.sh -o /tmp/bootstrap-master.sh
  - bash /tmp/bootstrap-master.sh
```

After bootstrap:
- Register `/etc/salt/pki/master/ssh/salt.pub` and `/etc/salt/pki/master/ssh/pillar.pub` as read-only deploy keys on the `infra-salt` and `infra-salt-pillar` repositories.
- Add public key of `/etc/salt/pki/master/age/key.txt` to `.sops.yaml` in `infra-salt-pillar` repository and reencrypt all secrets.
- Run `salt '*' state.apply`.
