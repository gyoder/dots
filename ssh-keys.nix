{
  host,
  principals ? host.sshPrincipals or [ ],
  extraKeys ? [ ],
}:

let
  allowedPrincipals = [
    "t:human"
    "h:${host.name}"
  ]
  ++ principals;
  certificateAuthority = builtins.replaceStrings [ "\n" ] [ "" ] (builtins.readFile ./ssh-ca.pub);
in
[
  "cert-authority,principals=\"${builtins.concatStringsSep "," allowedPrincipals}\" ${certificateAuthority}"
  "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIA6Eq2yVsZrCH8so7f3ygH0UWp6WkOxbhLNFC9QewKwoAAAABHNzaDo= grace.pink"
]
++ extraKeys
