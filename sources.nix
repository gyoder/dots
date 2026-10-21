{
  darwin = builtins.fetchTarball {
    url = "https://github.com/nix-darwin/nix-darwin/archive/f0ec2b3fae4df92ea7788359aef9e07bb88d720f.tar.gz";
    sha256 = "1awksjvj7xx5p94v8b68ygzs7v406z3nhvqfml2bil95vfjkinlf";
  };
  nixpkgs = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/1d834e11a48b443e3ede785cc58158a1d725d016.tar.gz";
    sha256 = "09kcv00cq3jy0vwj73a46vnsy7pzv05y3ymia3cdsqjddjvpyj1b";
  };
  home-manager = builtins.fetchTarball {
    url = "https://github.com/nix-community/home-manager/archive/975cea5f20d2a5e7e008f68da9043e7bb5c0e928.tar.gz";
    sha256 = "0a0vdrld2i2bqqdwib7qiqlnvszsfni0l5gcpr3slpg93sqi4rvh";
  };
  microvm = builtins.fetchTarball {
    url = "https://github.com/microvm-nix/microvm.nix/archive/f13928fe9900e91709d7ce581eefa47eaafa79e1.tar.gz";
    sha256 = "08b7lqmrkgn0n5smzk1h24488lnf75a09py0z7pzia0afcxpfg4d";
  };
}
