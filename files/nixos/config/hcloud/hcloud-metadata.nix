{ stdenv, config, pkgs, ... }:

with pkgs.python3Packages;

let
  hcloud-metadata = callPackage ({ stdenv, pkgs }: stdenv.mkDerivation {
    pname = "hcloud-metadata";
    src = ./hcloud-metadata;
    version = "1";

    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/hcloud-metadata
      patchShebangs $out/bin/hcloud-metadata
    '';
    propagatedBuildInputs = with pkgs; [ (python3.withPackages (f: [f.pyyaml])) jq ];
  }) {};
in {
  systemd.services.hcloud-dl-metadata = {
    description = "Download cloud-init & hetzner network metadata";
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "!/etc/hcloud-metadata.json";
    serviceConfig.Type = "oneshot";
    serviceConfig.DynamicUser = "yes";
    serviceConfig.ExecStart = "${hcloud-metadata}/bin/hcloud-metadata";
    serviceConfig.StandardOutput = "truncate:/etc/hcloud-metadata.json";
    wantedBy = [ "multi-user.target" ];
  };
  systemd.services.hcloud-dl-userdata = {
    description = "Download cloud-init userdata";
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "!/etc/hcloud-userdata";
    serviceConfig.Type = "oneshot";
    serviceConfig.DynamicUser = "yes";
    serviceConfig.ExecStart = ''
      ${pkgs.curl}/bin/curl --fail -s http://169.254.169.254/hetzner/v1/userdata
    '';
    serviceConfig.StandardOutput = "truncate:/etc/hcloud-userdata";
    wantedBy = [ "multi-user.target" ];
  };
}
