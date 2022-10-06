#!/usr/bin/env bash

set -e

function install_linux_packages() {
  apt update && apt upgrade -y

  apt install -y --no-install-recommends \
    bat \
    curl \
    delta \
    emacs \
    ffmpeg \
    git \
    make \
    gnupg \
    htop \
    jq \
    pandoc \
    ripgrep \
    stow \
    tmux \
    unzip \
    vim \
    yarn \
    zip \
    zsh

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

  BREW_PACKAGES=(git zsh bat delta colima ffmpeg htop jq lsd stow tmux unzip docker)
  for package in "${BREW_PACKAGES[@]}"; do
    if [[ -z "$(command -v $package)" ]]; then
      brew install "$package"
    fi
  done


  CASK_PACKAGES=(macvim iterm2 calibre mpv obs vcv-rack visual-studio-code arduino)
  for package in "${CASK_PACKAGES[@]}"; do
    if ! brew list --cask | grep -q "$package" &> /dev/null; then
      brew install --cask "$package"
    fi
  done

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

function install_asdf() {
  if [[ ! -d "$HOME/.asdf" ]]; then
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.10.2
  fi

  source "$HOME/.asdf/asdf.sh"

  if ! asdf list | grep -q "golang" &> /dev/null; then 
    asdf plugin add golang https://github.com/kennyp/asdf-golang.git
  fi

  if ! asdf list | grep -q "nodejs" &> /dev/null; then 
    asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
  fi
}

function install_direnv() {
  if [[ -z "$(command -v direnv)" ]]; then
    asdf plugin add direnv
  fi

  asdf direnv setup \
    --shell zsh \
    --version latest 

  echo ""
}

function install_fonts() {
  if [[ ! -d "$HOME/.fonts" ]]; then
    git clone https://github.com/themichaelyang/programming-fonts.git $HOME/.fonts
  fi

  pushd $HOME/.fonts
  ./install.sh 
  popd
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
  install_asdf
  install_direnv
  install_fonts

  setup_dotfiles
}

main
