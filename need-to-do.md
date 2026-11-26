# Need to do: homelab secrets

Nextcloud and FreshRSS read admin passwords from `/run/agenix/…`, but their
`age.secrets` blocks are commented out, so `nextcloud-setup` and
`freshrss-config` fail on first start until these steps are done. The other
homelab services (Jellyfin, Audiobookshelf, Paper, the website, tuwunel) need
no secrets.

## 1. Add the homelab as a recipient

After installing NixOS on the homelab:

1. Copy its host key: `ssh homelab cat /etc/ssh/ssh_host_ed25519_key.pub`
2. In `secrets/secrets.nix`, add it to the `let` block, e.g.
   `homelab = "ssh-ed25519 AAAA…";`

## 2. Create the secrets

Add both to `secrets/secrets.nix`:

```nix
"nextcloud-admin.age".publicKeys = [ mlabrecque homelab ];
"freshrss-admin.age".publicKeys = [ mlabrecque homelab ];
```

Then encrypt each one (the contents are the plain password, no `KEY=`):

```sh
cd secrets
agenix -e nextcloud-admin.age
agenix -e freshrss-admin.age
```

`git add` both `.age` files so the flake can see them.

## 3. Enable them

Uncomment the `age.secrets` block in:

- `modules/server/nextcloud.nix` (`nextcloud-admin`, owner `nextcloud`)
- `modules/server/freshrss.nix` (`freshrss-admin`, owner `freshrss`)

Check with
`nix eval .#nixosConfigurations.homelab.config.system.build.toplevel.drvPath`.
