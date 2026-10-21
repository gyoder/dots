{
  darwin = builtins.fetchTarball {
    url = "https://github.com/nix-darwin/nix-darwin/archive/4cff07de74b50e64bdd68cd4e722ab5b6b35ee48.tar.gz";
    sha256 = "057jwn4wwx4rkfl5av7ch9nbqsz1jrlcwjcc6kyf75plxfkn40d1";
  };
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/ac6b2166e7a9375683b8e98f860f273222337b16.tar.gz";
    sha256 = "0k6m5apwzg36qkm3wil1pf4q0lv1hp7r2imx4nfz9bfssnk9gj5w";
  };
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/6b88c12cc6d234de4888f5d21076fb11199d0844.tar.gz";
    sha256 = "1nsm7hqv48ll552x3jac06nc74kpxxsljqzq9r0jnk71d0p65ig6";
  };
  microvm = builtins.fetchTarball {
    url = "https://github.com/microvm-nix/microvm.nix/archive/f13928fe9900e91709d7ce581eefa47eaafa79e1.tar.gz";
    sha256 = "08b7lqmrkgn0n5smzk1h24488lnf75a09py0z7pzia0afcxpfg4d";
  };
}
