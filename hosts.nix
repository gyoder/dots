{
  turing = {
    user = "grace";
    home = "/Users/grace";
    system = "aarch64-darwin";
    type = "darwin";
  };

  "cs.purdue.edu" = {
    user = "yoder177";
    home = "/homes/yoder177";
    system = "x86_64-linux";
    type = "home";
    ssh.hostname = "data.cs.purdue.edu";
  };

  vulcan = {
    sshPrincipals = [ "t:dev" ];
    user = "scie";
    home = "/home/scie";
    system = "x86_64-linux";
    type = "home";
    ssh = {
      hostname = "vulcan.moe";
      port = 4225;
    };
  };

  dijkstra = {
    sshPrincipals = [ "t:dev" ];
    user = "grace";
    home = "/home/scie";
    system = "x86_64-linux";
    type = "nixos";
  };

  knuth = {
    sshPrincipals = [ "t:dev" ];
    user = "grace";
    home = "/home/scie";
    system = "x86_64-linux";
    type = "nixos";
  };

  lovelace = {
    user = "grace";
    home = "/home/grace";
    system = "x86_64-linux";
    type = "nixos";
  };

  portable = {
    sshPrincipals = [ "t:dev" ];
    user = "grace";
    home = "/home/grace";
    system = "x86_64-linux";
    type = "nixos";
  };
}
