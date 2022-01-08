variable "extra-packages" {
  type    = list(string)
  default = []
}

variable "hcloud-servertype" {
  type    = string
  default = "cx11"
}

variable "hcloud-token" {
  type      = string
  default   = "${env("HCLOUD_TOKEN")}"
  sensitive = true
}

variable "nix-channel" {
  type    = string
  default = "21.11"
}

variable "nix-config-path" {
  type    = string
  default = "files/nixos/config/hcloud/user/"
}

variable "nix-release" {
  type    = string
  default = "2.5.1"
}

variable "root-ssh-key" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCo31gjjKXTeVYH6Oy7xGqT7rfsBkhLOFDsDEwkfNvVP8jzobumSPfIlBVKLAYU3A+5lPlICLVfnkGSIkLO+fLb3c54HQ8GHb2R/+cq5N/JicMu7LAmYy7ADF7cwl8UklLYm9i2UrZtsD+Xi/2KeGWqpbscs6HNqOoQjoOrQHOqpJW0kaAr+IgMEL+ECh1/loS4J3cVTk9Xi+jZbNDRR8BtqZ9WEpYSftqGLNHeRTYq35kw0FkV5CKhDoKBDLyTHU/sSyic7NpIWd7MI0CzMYmb5bSAdW19KdgNbz4Y+yvZsD9LZ6rvy4MbwWXAL0f/kSKMxh7Zw57sYmgf0Q8O6LIc5cR/kzs63FChWyoIHEhbtzC0kSNatCrN6UYG/cHehUvdpQVzf5zuvlErw0C4NxYth8l5QrcwoOKQNeiRYOivyUaiKEtcVmv9KD91IPhzwCv3v6DVhfc61gmjRL/G4Ipzv61M9zGJXLfOytxQ6uZVkfIQ9em+/YqVyWV/TezprYhLVwHPZ5c9/qLvnPRidrCAJxGUdtB3LHM2swsAmx1cS8m5jxggWIBmwZB5uxCliF2XHXu0+rUmmi0sTX4EcL5HlXuzMBW3vtKVTy4kGHqvNjIQx7GGcs4Bfp3qfR893a1xrZQoOAeuLvwGDa1otAQLPsZw4nuA8XFpg0GP35bvGQ== openpgp:0xB487F34B"
}

variable "system-keymap" {
  type    = string
  default = "us"
}

variable "system-locale" {
  type    = string
  default = "en_US.UTF-8"
}

variable "system-timezone" {
  type    = string
  default = "UTC"
}

locals {
  arch-release = "${ legacy_isotime("2006-01") }-01"
  build-id = "${ uuidv4() }"
  build-labels  = {
    os-flavor              = "nixos"
    "nixos/channel"        = "${ var.nix-channel }"
    "nixos/nix.release"    = "${ var.nix-release }"
    "packer.io/build.id"   = "${ local.build-id }"
    "packer.io/build.time" = "{{ timestamp }}"
    "packer.io/version"    = "{{ packer_version }}"
  }
}

source "hcloud" "nixos" {
  server_type = "${ var.hcloud-servertype }"
  image = "debian-11"
  rescue      = "linux64"
  location    = "hel1"
  snapshot_name = "nixos-{{ timestamp }}"
  snapshot_labels = local.build-labels
  ssh_username  = "root"
  token         = "${ var.hcloud-token }"
}

build {
  sources = [ "source.hcloud.nixos" ]

  provisioner "shell" {
    script           = "files/filesystem.sh"
    environment_vars = [ "LABEL=${local.build-id}" ]
  }

  provisioner "file" {
    destination = "/tmp/key-${local.build-id}.gpg"
    source      = "files/nixos/key.gpg"
  }

  provisioner "shell" {
    inline = [
      "gpg --batch --import /tmp/key-${local.build-id}.gpg",
      "mkdir -p /mnt/etc/nixos/hcloud/",
    ]
  }

  provisioner "file" {
    destination = "/mnt/etc/nixos/"
    source      = "files/nixos/config/"
  }

  provisioner "file" {
    destination = "/mnt/etc/nixos/hcloud/user/"
    source      = "${var.nix-config-path}"
  }

  provisioner "shell" {
    script           = "files/nixos/install.sh"
    environment_vars = [
      "NIX_RELEASE=${var.nix-release}",
      "NIX_CHANNEL=${var.nix-channel}",
      "ROOT_SSH_KEY=${var.root-ssh-key}",
      "KEYMAP=${var.system-keymap}",
      "LOCALE=${var.system-locale}",
      "TIMEZONE=${var.system-timezone}",
      "EXTRA_PACKAGES=${join(" ", var.extra-packages)}",
    ]
  }

  post-processor "manifest" {
    custom_data = local.build-labels
  }
}
