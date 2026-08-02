packer {
  required_plugins {
    tart = {
      version = ">= 1.21.0"
      # ref: https://github.com/cirruslabs/packer-plugin-tart
      source = "github.com/cirruslabs/tart"
    }
  }
}

variable "configs_repository" {
  type    = string
  default = "https://github.com/Neko-nos/configs.git"
}

variable "vm_name" {
  type    = string
  default = "codex-macos"
}

variable "timezone" {
  type    = string
  default = "Asia/Tokyo"
}

source "tart-cli" "codex" {
  vm_base_name = "ghcr.io/cirruslabs/macos-tahoe-vanilla:latest"
  vm_name      = var.vm_name
  cpu_count    = 2
  memory_gb    = 4
  headless     = true
  ssh_username = "admin"
  ssh_password = "admin"
  ssh_timeout  = "120s"
}

build {
  sources = ["source.tart-cli.codex"]

  provisioner "shell-local" {
    command = "${path.root}/configure_host.zsh ${var.vm_name}"
  }

  provisioner "shell" {
    inline = [
      "mkdir -p \"$HOME/.ssh\"",
      "chmod 0700 \"$HOME/.ssh\"",
    ]
  }

  provisioner "file" {
    source      = pathexpand("~/.ssh/id_ed25519_${var.vm_name}.pub")
    destination = "/Users/admin/.ssh/authorized_keys"
    generated   = true
  }

  provisioner "shell" {
    inline = [
      "chmod 0600 \"$HOME/.ssh/authorized_keys\"",
      "sudo systemsetup -settimezone '${var.timezone}'",
      "defaults write NSGlobalDomain AppleICUForce24HourTime -bool true",
      # Password less sudo
      "sudo mkdir -p /private/etc/sudoers.d",
      "sudo chmod 0755 /private/etc/sudoers.d",
      "printf 'admin ALL=(ALL) NOPASSWD: ALL\\n' | sudo tee /private/etc/sudoers.d/admin >/dev/null",
      "sudo chmod 0440 /private/etc/sudoers.d/admin",
      # This temporary file prompts the 'softwareupdate' utility to list the Command Line Tools
      # ref: https://github.com/Homebrew/install/blob/ca0130bd52235f2fcb2bf23cfdda004bc5d250c1/install.sh#L848
      "sudo touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress",
      "sudo softwareupdate -i \"$(softwareupdate -l | grep -B 1 'Command Line Tools' | awk -F'*' '/^ *\\*/ {print $2}' | sed -e 's/^ *Label: //' -e 's/^ *//' | sort -V | tail -n1)\"",
      "sudo xcode-select --switch /Library/Developer/CommandLineTools",
      "sudo rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress",
      "git clone \"${var.configs_repository}\" \"$HOME/configs\"",
      # ref: https://learn.chatgpt.com/docs/sandboxing?surface=cli#cli-configure-defaults
      "sed -i '' 's/^default_permissions = .*/default_permissions = \":danger-full-access\"/' \"$HOME/configs/common/codex/config.toml\"",
      "sed -i '' 's/^approval_policy = .*/approval_policy = \"never\"/' \"$HOME/configs/common/codex/config.toml\"",
    ]
  }

  # shell.inline runs while Packer builds the image, not when a user starts the resulting VM.
  # A login file defers the reminder until the VM's first interactive shell.
  provisioner "file" {
    content = <<-EOT
      export LANG=C.UTF-8

      if [[ -o interactive && ! -e "$HOME/.codex-vm-first-run-prompt-shown" ]]; then
          print -r -- 'To finish setup, run: cd ~/configs/Mac/install && zsh ./install.sh'
          touch "$HOME/.codex-vm-first-run-prompt-shown"
      fi
    EOT

    destination = "/Users/admin/.zlogin"
  }
}
