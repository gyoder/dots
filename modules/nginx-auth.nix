{ }:

let
  authLocation = endpoint: {
    proxyPass = "http://127.0.0.1:9091/api/authz/${endpoint}";
    recommendedProxySettings = false;
    extraConfig = ''
      internal;
      auth_request off;
      proxy_pass_request_body off;
      proxy_set_header Content-Length "";
      proxy_set_header Connection "";
      proxy_set_header X-Original-URL $scheme://$host$request_uri;
      proxy_set_header X-Original-Method $request_method;
      proxy_set_header X-Forwarded-For $remote_addr;
      proxy_set_header Cookie $http_cookie;
      proxy_set_header Authorization $http_authorization;
    '';
  };
in
{
  locations = {
    "= /_authelia" = authLocation "auth-request";
    "= /_authelia_git" = authLocation "git";
  };

  browser = ''
    auth_request /_authelia;
    auth_request_set $auth_redirect $upstream_http_location;
    error_page 401 =302 $auth_redirect;
    auth_request_set $auth_user $upstream_http_remote_user;
    auth_request_set $auth_groups $upstream_http_remote_groups;
    auth_request_set $auth_email $upstream_http_remote_email;
    auth_request_set $auth_name $upstream_http_remote_name;
    proxy_set_header Remote-User $auth_user;
    proxy_set_header Remote-Groups $auth_groups;
    proxy_set_header Remote-Email $auth_email;
    proxy_set_header Remote-Name $auth_name;
  '';

  git = ''
    auth_request /_authelia_git;
    proxy_set_header Authorization "";
  '';
}
