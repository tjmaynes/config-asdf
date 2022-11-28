#!/usr/bin/env bash

set -e

function ensure_program_installed() {
  if [[ -n "$1" ]] && [[ -z "$(command -v $1)" ]]; then
    if [[ "$OSTYPE" = "darwin"* ]]; then
      brew install "$1"
    else
      apt-get install -y --no-install-recommends "$1"
    fi
  fi
}

function install_macos_store_package() {
  if [[ ! -d "/Applications/$1.app" ]]; then
    mas install "$2"
  fi
}

function install_brew_cask_package() {
  if ! brew list --cask | grep -q "$1" &> /dev/null; then
    brew install --cask "$1"
  fi
}

function install_asdf_plugin() {
  if [[ ! -d "$HOME/.asdf" ]]; then
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.10.2
  fi

  if [[ -z "$(command -v asdf)" ]]; then
    source "$HOME/.asdf/asdf.sh"
  fi

  if ! asdf list | grep -q "$1" &> /dev/null; then
    asdf plugin add "$1" "$2"
  fi
}

function install_docker_on_linux() {
  if [[ -z "$(command -v docker)" ]]; then
    apt install apt-transport-https ca-certificates curl software-properties-common -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

    apt install docker-ce -y

    systemctl start docker
    systemctl enable docker

    usermod -aG docker tjmaynes
    newgrp docker
  fi
}

function install_colima_on_linux() {
  COLIMA_VERSION=v0.4.6

  if [[ -z "$(command -v colima)" ]]; then
    curl -LO https://github.com/abiosoft/colima/releases/download/${COLIMA_VERSION}/colima-$(uname)-$(uname -m)
    install colima-$(uname)-$(uname -m) /usr/local/bin/colima
  fi
}

function install_fonts() {
  if [[ ! -d "$HOME/.fonts" ]]; then
    git clone https://github.com/themichaelyang/programming-fonts.git "$HOME/.fonts"
  fi

  pushd "$HOME/.fonts"
  ./install.sh 
  popd
}

function install_linux_packages() {
  apt update && apt upgrade -y

  DEB_PACKAGES=(bat curl delta emacs ffmpeg git gnupg htop make jq pandoc ripgrep stow tmux unzip vim zip zsh)
  for package in "${DEB_PACKAGES[@]}"; do
    ensure_program_installed "$package"
  done

  echo ""
}

function install_macos_packages() {
  if [[ "$(uname -m)" = "arm64" ]]; then
    export PATH=/opt/homebrew/bin:$PATH
  else
    export PATH=/usr/local/bin:$PATH
  fi

  if [[ -z "$(command -v brew)" ]]; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  brew update && brew upgrade

  BREW_PACKAGES=(git zsh bat delta colima ffmpeg htop jq lsd stow tmux unzip docker mas)
  for package in "${BREW_PACKAGES[@]}"; do
    ensure_program_installed "$package"
  done

  CASK_PACKAGES=(macvim iterm2 calibre mpv obs vcv-rack visual-studio-code arduino discord notion raspberry-pi-imager zoom jetbrains-toolbox kid3 qutebrowser)
  for package in "${CASK_PACKAGES[@]}"; do
    install_brew_cask_package "$package"
  done

  install_macos_store_package "Final Cut Pro" "424389933"
  install_macos_store_package "DaisyDisk" "411643860"
  install_macos_store_package "Bitwarden" "1352778147"
  install_macos_store_package "Amphetamine" "937984704"

  install_fonts
}

function install_packages() {
  if [[ "$OSTYPE" = "darwin"* ]]; then
    install_macos_packages
  else
    install_linux_packages
  fi
}

function install_zprezto() {
  if [[ ! -d "$HOME/.zprezto" ]]; then
    git clone --recursive https://github.com/sorin-ionescu/prezto.git "$HOME/.zprezto"
  fi
}

function install_asdf_plugins() {
  install_asdf_plugin "golang" "https://github.com/kennyp/asdf-golang.git"
  install_asdf_plugin "nodejs" "https://github.com/asdf-vm/asdf-nodejs.git"
  install_asdf_plugin "java" "https://github.com/halcyon/asdf-java.git"
  install_asdf_plugin "direnv" "https://github.com/asdf-community/asdf-direnv.git"
}

function install_direnv() {
  asdf direnv setup \
    --shell zsh \
    --version latest 

  echo ""
}

function setup_dotfiles() {
  if [[ ! -d "../dotfiles" ]]; then
    echo "Please place 'dotfiles' right outside the root of the project"
    exit 1 
  fi

  cd ../dotfiles && make setup
}

function main() {
  install_packages

  install_zprezto
  install_asdf_plugins
  install_direnv

  setup_dotfiles

  asdf install
}

main
