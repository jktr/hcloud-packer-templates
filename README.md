# hcloud-packer-templates

This repo is used to build linux images (as snapshots) for use with
[Hetzner Cloud](https://www.hetzner.de/cloud) by means of HashiCorp's
[Packer](https://packer.io/).

Templates for the following distros are currently provided:

  - archlinux
  - nixos

I recommend the use of Hetzner's
[hcloud](https://github.com/hetznercloud/cli/tree/master/cli) command
line tool to manage the resulting images. Hetzner also provides a dedicated
[Terraform Provider](https://www.terraform.io/docs/providers/hcloud/index.html)
that you can use to build servers from these images. Please note that
your images cannot yet be (easily) exported from Hetzner's Cloud.

## building the images

Please ensure that you have done the following:

  - installed packer on your development machine
  - set the HCLOUD_TOKEN environment variable to your API token
  - reviewed/overriden the templates' variables (as necessary)

### example

  - `$ packer build templates/nixos.json` to build a nixos image
  - `$ cat nixos-manifest.json` for details about this (and past) built images

Debug a build:

  - `$ packer build -debug -on-error=ask packer/nixos.json`
  - `$ ssh -F/dev/null -i ssh_key_hcloud.pem root@XXX.XXX.XXX.XXX -o StrictHostKeyChecking=no`

### known issues

- The archlinux bootstrap image's filename is derived from its release
  day. There's no good way to automatically get this date.
  Set `-var arch-image=archlinux-bootstrap-20XX.XX.XX-x86_64.tar.gz` in this case.

- Verifying the archlinux bootstrap image is relatively complex due to
  the setup the archlinux team uses. We don't properly derive
  developer key trust from the master key, but instead pin the key of
  the developer that usually signs the releases.

- The images get their IPv4 via DHCP, but their IPv6 prefix needs to
  be derived some other way when the /64 becomes available to the
  resulting server.

## GPG Keys

The upstream for the GPG keys used by the installation scripts can be found on these pages:

  - archlinux: https://www.archlinux.org/master-keys/
  - nix: https://nixos.org/nix/download.html

## License

You can redistribute and/or modify these files unter the terms of the
GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any
later version. See the LICENSE file for details.
