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
  build-labels = {
    os-flavor               = "archlinux"
    "archlinux/iso.release" = "${ local.arch-release }"
    "packer.io/build.id"    = "${ local.build-id }"
    "packer.io/build.time"  = "{{ timestamp }}"
    "packer.io/version"     = "{{ packer_version }}"
  }
}

source "hcloud" "archlinux" {
  server_type  = "${ var.hcloud-servertype }"
  image = "debian-11"
  #image_filter = {
  #  with_selector = [ "os_flavor=debian" ]
  #  most_recent = true
  #}
  rescue       = "linux64"
  location     = "hel1"
  snapshot_name = "archlinux-{{ timestamp }}"
  snapshot_labels = local.build-labels
  ssh_username  = "root"
  token         = "${ var.hcloud-token }"
}

build {
  sources = [ "source.hcloud.archlinux" ]

  provisioner "shell" {
    script           = "files/filesystem.sh"
    environment_vars = [ "LABEL=${local.build-id}" ]
  }

  provisioner "file" {
    destination = "/mnt/"
    source      = "files/archlinux/root/"
  }

  provisioner "file" {
    destination = "/tmp/key-${local.build-id}.gpg"
    source      = "files/archlinux/key.gpg"
  }

  provisioner "shell" {
    inline = [
      "gpg --batch --import /tmp/key-${local.build-id}.gpg",
      "chmod --recursive u=rwX,g=rX,o=rX /mnt",
      "chmod --recursive u=rwx,g=rx,o=rx /mnt/usr/local/bin/*",
    ]
  }

  provisioner "shell" {
    script           = "files/archlinux/install.sh"
    environment_vars = [
      "ARCH_RELEASE=${local.arch-release}",
      "EXTRA_PACKAGES=${join(" ", var.extra-packages)}",
      "KEYMAP=${var.system-keymap}",
      "LOCALE=${var.system-locale}",
      "TIMEZONE=${var.system-timezone}",
    ]
  }

  post-processor "manifest" {
    custom_data = local.build-labels
  }
}
