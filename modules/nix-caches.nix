# Shared cache data for both NixOS and standalone Home Manager.
{
  substituters = [
    "https://codex-cli.cachix.org"
    "https://claude-code.cachix.org"
  ];
  trusted-public-keys = [
    "codex-cli.cachix.org-1:1Br3H1hHoRYG22n//cGKJOk3cQXgYobUel6O8DgSing="
    "claude-code.cachix.org-1:YeXf2aNu7UTX8Vwrze0za1WEDS+4DuI2kVeWEE4fsRk="
  ];
}
