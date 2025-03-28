# Getting Started with Neusis

**Purpose**: This document provides a complete guide for new users to set up their account and environment in the Neusis system. It covers everything from initial SSH key generation to customizing your home environment, with clear steps and explanations for each part of the process.

## Initial Setup

### 1. Generate SSH Keys

First, you'll need to generate a secure SSH key pair using the ED25519 algorithm:

```bash
ssh-keygen -t ed25519
```

This will create your SSH key pair that will be used for secure authentication across the system.

### 2. Create Your User Configuration

1. Fork and check out this repository.

2. Create your user config directory: `homes/<your-username>`

Copy the example user directory structure from `homes/shsingh` to your new user config directory to get started:

```
shsingh/
├── home.nix
├── id_ed25519.pub
└── machines/
    ├── oppy.nix
    └── spirit.nix
```

3. Replace the SSH public key in `id_ed25519.pub` with your own public key (which is in your `~/.ssh/id_ed25519.pub`)

4. Configure `home.nix`:
```nix
home = {
  username = "<your-username>";
  homeDirectory = "/home/<your-username>";
  # ... existing code ...
};
```

5. Set your Git information in `machines/*.nix`:
```nix
(import ../../common/dev/git.nix {
  username = "Your Full Name";
  userEmail = "your.email@example.com";
  id_ed25519_pub = builtins.readFile ../id_ed25519.pub;
})
```

## Customizing Your Home Environment

You will want to customize your home environment in a number of ways. For example installing programs specific to your user account, customizing your shell prompt, modifying your `.bashrc` or `.zshrc`, etc.

To do this you will need to modify `neusis/homes/<username>/home.nix`. The normal process is to make changes there, send a PR to the `neusis` repo, have the admin pull the changes and rebuild (`nix switch`).

However that process is time-consuming, and requires the admin to manually approve your changes (or set up some automation to do so), which would defeat one of the advantages of using nix which is the ability to install programs without `sudo`. It also doesn't afford any way to check if your changes are valid or work as expected. Going through the above process only to find a syntax error would be highly annoying.

Instead you can use `home-manager` to iteratively modify your `home.nix` and rebuild locally to see the changes.

### Setting Up Local Development

To enable this, you will first need to make an entry in `neusis/flake.nix` allowing you access to `home-manger`. Copy-paste one of the entries already there, under `homeConfigurations`, and replace the necessary parts specific to your `<username>` and `<machine>`. A standard entry will look like this:

```
"<username>@<machine>" = lib.homeManagerConfiguration {
  pkgs = pkgsFor.x86_64-linux;
  extraSpecialArgs = { inherit inputs outputs; };

  modules = [
    inputs.agenix.homeManagerModules.default
    ./homes/<username>/machines/<machine>.nix
  ];
```

Replace `<username>` with your user name, and `<machine>` with the relevant server (e.g. `oppy` or `spirit`).

You will need to issue a PR, and have the admin accept these changes. However this is a one-time process, and from then on you will be able to make changes to your home without needing to go through a PR each time.

### Testing Your Changes

Once the above change is made, you may modify `neusis/homes/<username>/home.nix`. After making changes run the following from the root of `neusis` (the top level directory):

```bash
cd ~/neusis # or wherever the neusis repo lives for you
nix-shell -p home-manager
home-manager switch --flake .#<username>@<machine>
exit
```

Note that the `#` symbol above in `.#<username>@<machine>` does not denote a comment. It is part of the syntax to the `home-manager switch --flake` command.

Again, make sure to replace with your actual `username` and the `machine` you're targeting (e.g. `oppy` or `spirit`).

If you have installed new programs, they should now be available (try `which <program_name>`). If you have modified your shell login file (e.g. `.bashrc` or `.zshrc`), you will need to source it (e.g. `source ~/.zshrc`) or logout and log back in to see the changes.

### Submitting Changes

Once you are satisfied with your customizations, issue a PR. Since running `home-manager switch` immediately reflects your changes to `home.nix`, you do not have to wait for the PR to be merged, however it is still important to make a PR with your changes so that they can *eventually* be incorporated into the `main` branch. 