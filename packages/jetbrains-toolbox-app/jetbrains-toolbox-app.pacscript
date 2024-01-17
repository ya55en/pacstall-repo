# shellcheck shell=bash disable=SC2034

pkgname='jetbrains-toolbox'
name="${pkgname}-app"
gives="${pkgname}"
breaks=("${pkgname}" "${pkgname}-deb" "${pkgname}-bin")
replace=("${pkgname}")
pkgver='2.1.3.18901'
maintainer='ya55en <ya55en.foo@gmail.com>'
url="https://download-cdn.jetbrains.com/toolbox/${pkgname}-${pkgver}.tar.gz"
hash='d6334bad157907f2f749fdb70e0fc9eeff902ae75962ab2f28546f996441bf49'
homepage='https://www.jetbrains.com/toolbox-app/'
pkgdesc="Manage your JetBrains IDEs the easy way

Manage your JetBrains tools with ease: Install, Update automatically, Update
the plugins together with IDE, Roll back and downgrade.

Save time and effort maintaining your IDEs. See what's new. Maintain multiple
versions side by side. Open projects instantly. Connect to team tools.
Integrate with GitHub, GitLab, or Bitbucket.

https://www.jetbrains.com/toolbox-app/
"

# REPO_BASE_URL='https://raw.githubusercontent.com/ya55en/pacstall-repo/main'
REPO_BASE_URL='file:///home/ya55en/Work/Mine/pacstall-repo'

package() {
  _ensure_symlink_path_clean

  sudo usermod -aG users "$USER"
  sudo install -d -m775 -g users "${pkgdir}/opt/JetBrains/Toolbox/self-extract/"
  sudo install -m775 -g users jetbrains-toolbox "${pkgdir}/opt/JetBrains/Toolbox/self-extract/"
}

pre_install() {
  set -x

  install -d -g users -m775 /opt/JetBrains/
  install -d -m755 ~/.local/share

  ln -s /opt/JetBrains "$HOME/.local/share/JetBrains"

  # Download and install the .desktop file
  curl -sSLO "$REPO_BASE_URL/packages/${pkgname}-app/${pkgname}.desktop"
  sudo install -D -m664 "${pkgname}.desktop" \
    "${homedir}/.local/share/applications/${pkgname}.desktop"

  set +x
}

post_install() {
  set -x

  install -d -g users -m775 /opt/JetBrains/toolbox-apps
  install -d -g users -m775 /opt/JetBrains/toolbox-scripts

  # Download and install .settings.json
  curl -sSLO "$REPO_BASE_URL/packages/${pkgname}-app/initial-settings.json"

  # First run - results in self-extractoin and self-installation
  /opt/JetBrains/Toolbox/self-extract/jetbrains-toolbox

  sudo install -D -m664 initial-settings.json /opt/JetBrains/Toolbox/.settings.json

  chgrp -R users /opt/JetBrains
  chmod -R g+rw /opt/JetBrains

  _wait_extractor_pid

  unset REPO_BASE_URL

  # TODO: Print instructions to the user
  set +x
}

_ensure_symlink_path_clean() {
  local _symlink_path="$HOME/.local/share/JetBrains"

  ! [ -e "$_symlink_path" ] && {
    echo "D: $_symlink_path does NOT exist, continue."
    return
  }

  echo "D: $_symlink_path EXISTS:"

  [ -h "$_symlink_path" ] && {
    echo "D: $_symlink_path is a symlink..."
    rm "$_symlink_path"
    echo "D: REMOVED, continue."
    return
  }

  rmdir "$_symlink_path" && {
    echo "D: $_symlink_path is an empty directory: REMOVED, continue."
    return
  }

  printf "
  FATAL: File or directory '%s/.local/share/JetBrains' exists. It is mandatory
    for this installation to place a symlink there. Consider removing whatever
    is at this location and try again. Terminating.\n\n" "$HOME"

  exit 5
}

_wait_extractor_pid() {
  local pid_to_wait
  pid_to_wait=$(ps ax | awk '/jetbrains-toolbox[ \t]+--wait-for-pid/ && ! /awk/ {print $7}' | head -1)

  printf "I: Waiting for PID %s..." "$pid_to_wait"
  while ps ax | awk '{print $1}' | grep -q "$pid_to_wait"; do
    sleep 0.5
  done
  printf " Done.\n"
}

post_remove() {
  set -x

  local _have_apps=false

  if ! rmdir /opt/JetBrains/toolbox-scripts 2> /dev/null; then
    [ -e /opt/JetBrains/toolbox-scripts ] && {
      echo "WARN: /opt/JetBrains/toolbox-scripts not empty so not removed."
      _have_apps=true
    }
  fi

  if ! rmdir /opt/JetBrains/toolbox-apps 2> /dev/null; then
    [ -e /opt/JetBrains/toolbox-apps ] && {
      echo "WARN: /opt/JetBrains/toolbox-apps not empty so not removed."
      _have_apps=true
    }
  fi

  [ "$_have_apps" = true ] && echo "
  ^^ If you want to remove the applications installed via the Toolbox, then you
     may need to take care of their settings data, as well as .desktop files,
     besides removing the above mentioned directories.
  "

  printf "I: Removing .desktop files..."
  rm -f "${homedir}/.local/share/applications/${pkgname}.desktop"
  rm -f "${homedir}/.config/autostart/${pkgname}.desktop"
  printf " Done.\n"

  printf "I: Removing main directory and cache files..."
  rm -rf "${homedir}/.cache/JetBrains/Toolbox/"
  rm -rf /opt/JetBrains/Toolbox/
  printf " Done.\n"

  unset REPO_BASE_URL

  set +x
}
