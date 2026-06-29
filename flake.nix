{
  description = "Custom foot NixOS module with themes";

  outputs = { self, ... }: {
    nixosModules.default = import ./foot-module.nix;
  };
}
