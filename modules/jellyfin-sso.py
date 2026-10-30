import os
from pathlib import Path
import sys
import xml.etree.ElementTree as ET


config_path = Path(sys.argv[1])
secret = Path(sys.argv[2]).read_text().strip()
if not secret or secret.startswith("$pbkdf2-") or secret.startswith("$argon2"):
    raise ValueError("Jellyfin needs the non-empty plaintext OIDC client secret")

root = ET.parse(config_path).getroot() if config_path.exists() else ET.Element("PluginConfiguration")
if root.find("SamlConfigs") is None:
    ET.SubElement(root, "SamlConfigs")
providers = root.find("OidConfigs")
if providers is None:
    providers = ET.SubElement(root, "OidConfigs")
item = next(
    (item for item in providers.findall("item") if item.findtext("key/string") == "authelia"),
    None,
)
if item is None:
    item = ET.SubElement(providers, "item")
    ET.SubElement(ET.SubElement(item, "key"), "string").text = "authelia"
    ET.SubElement(ET.SubElement(item, "value"), "PluginConfiguration")
provider = item.find("value/PluginConfiguration")

# this is so that it doesnt overwrite the links betweena ccounts
settings = {
    "OidEndpoint": "https://auth.gae.moe",
    "OidClientId": "jellyfin",
    "OidSecret": secret,
    "Enabled": "true",
    "EnableAuthorization": "true",
    "EnableAllFolders": "true",
    "PreserveAdminPermissions": "true",
    "EnableFolderRoles": "false",
    "EnableLiveTvRoles": "false",
    "EnableLiveTv": "false",
    "EnableLiveTvManagement": "false",
    "RoleClaim": "groups",
    "DefaultUsernameClaim": "preferred_username",
    "SchemeOverride": "https",
    "NewPath": "false",
    "DisableHttps": "false",
    "DisablePushedAuthorization": "true",
    "DoNotValidateEndpoints": "false",
    "DoNotValidateIssuerName": "false",
    "DoNotLoadProfile": "false",
    "OverrideDefaultScopes": "false",
    "OidAuthorizationParameters": "",
}
for name, value in settings.items():
    element = provider.find(name)
    if element is None:
        element = ET.SubElement(provider, name)
    element.text = value

for name, values in {"Roles": ["users"], "AdminRoles": [], "OidScopes": ["groups"]}.items():
    element = provider.find(name)
    if element is None:
        element = ET.SubElement(provider, name)
    element.clear()
    for value in values:
        ET.SubElement(element, "string").text = value

branding_path = Path(sys.argv[3])
branding = ET.parse(branding_path).getroot() if branding_path.exists() else ET.Element("BrandingOptions")
disclaimer = branding.find("LoginDisclaimer")
if disclaimer is None:
    disclaimer = ET.SubElement(branding, "LoginDisclaimer")
button = '''<form action="https://fin.gae.moe/sso/OID/start/authelia" id="authelia-signin">
  <button class="raised block emby-button button-submit">Sign in with auth.gae.moe</button>
</form>'''
if 'id="authelia-signin"' not in (disclaimer.text or ""):
    disclaimer.text = (disclaimer.text or "") + "\n" + button
css = branding.find("CustomCss")
if css is None:
    css = ET.SubElement(branding, "CustomCss")
rule = ".disclaimerContainer { display: block; }"
if rule not in (css.text or ""):
    css.text = (css.text or "") + "\n" + rule

os.umask(0o077)
for path, document in [(config_path, root), (branding_path, branding)]:
    temporary = path.with_suffix(".xml.tmp")
    with temporary.open("wb") as output:
        os.chmod(temporary, 0o600)
        ET.ElementTree(document).write(output, encoding="utf-8", xml_declaration=True)
    temporary.replace(path)
