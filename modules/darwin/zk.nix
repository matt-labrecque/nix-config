{
  lib,
  buildGoModule,
  src,
}:

buildGoModule {
  pname = "zk";
  version = "0.1.0";
  inherit src;
  vendorHash = "sha256-2adRLsTSd0vTGcis5FfOT5ZFgB420nvDqHkEEopmgec=";
}
