let
  hosts = {
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
    };

    vulcan = {
      user = "scie";
      home = "/home/scie";
      system = "x86_64-linux";
      type = "home";
    };

    dijkstra = {
      user = "scie";
      home = "/home/scie";
      system = "x86_64-linux";
      type = "home";
    };

    knuth = {
      user = "grace";
      home = "/home/scie";
      system = "x86_64-linux";
      type = "nixos";
    };
  };

  hostname = builtins.getEnv "NIX_HOST";
  name =
    if builtins.match "(.+\\.)?cs\\.purdue\\.edu" hostname != null then
      "cs.purdue.edu"
    else
      builtins.head (builtins.split "\\." hostname);
in
(hosts.${name} or (throw "Set NIX_HOST to a host in hosts.nix (got '${hostname}')."))
// { inherit name; }
