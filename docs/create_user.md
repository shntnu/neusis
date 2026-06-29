# Creating Your User Configuration

Fork and check out this repository.

## Steps

1. Create your user config directory: `homes/<your-username>`

Copy the example user directory structure from `homes/shsingh` to your new user config directory to get started:

```
shsingh/
├── home.nix
├── id_ed25519.pub
└── machines/
    ├── oppy.nix
    └── spirit.nix

```

2. Replace the SSH public key in `id_ed25519.pub` with your own public key (which is in your `~/.ssh/id_ed25519.pub`)

3. Configure `home.nix`:
```nix
home = {
  username = "<your-username>";
  homeDirectory = "/home/<your-username>";
  # ... existing code ...
};
```

4. Set your Git information in `machines/*.nix`:
```nix
(import ../../common/dev/git.nix {
  username = "Your Full Name";
  userEmail = "your.email@example.com";
  id_ed25519_pub = builtins.readFile ../id_ed25519.pub;
})
```

5. Register the user in `users/*.nix` (e.g. `users/cslab.nix`) under one of the
   four lists. The list determines what `lib/neusisOS.nix` does to the account:

   - `admins` — wheel + networkmanager + libvirtd + docker + podman. Use for
     maintainers who need `sudo`.
   - `regulars` — libvirtd + docker + podman, no `sudo`. Default for normal
     users.
   - `locked` — **the account exists and the SSH key is installed, but the
     login shell is forced to `nologin` and the password is locked (`!`)**.
     This means ssh authentication succeeds and then the session is
     immediately closed by `/nologin`. Use this only to retire an account
     while preserving its home directory; do not put new users here.
   - `guests` — minimal groups (input, podman, docker).

   To restore a previously-locked user, move their entry from `locked` back to
   `regulars` (or `admins`) and rebuild the machine.

## Tailscale access (out-of-band)

Neusis only manages tailscale on the *node* side (`machines/common/tailscale.nix`
brings the host up with `tsauthkey`). It does **not** manage who is allowed to
reach the node — that's controlled by the tailnet ACL in the Tailscale admin
console, which lives outside this repo.

After adding a user here, you must also grant them access in the Tailscale
admin UI. For cslab users that typically means adding them to:

- `group:ipdata` — grants reachability to the lab machines on the tailnet.

Without this step, `nixos-rebuild switch` will provision the account
correctly but the user still won't be able to reach the host over the mesh.
