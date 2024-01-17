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

# TODO: remove comments when not needed
#
# Create some directories:
# E.g. /opt/JetBrains/{toolbox-scripts,toolbox-apps,toolbox-self-extractor}
# ~/.local/share/JetBrains/Toolbox/ - do we need this?
# Warn the user NOT to change the two paths settings. (do we need this?)

# Move the self-extractor to /opt/JetBrains/toolbox-self-extractor
# Deal with the case it already exists (e.g. rename it)
# Execute it, -minimized if possible
# Wait for the extractor PID to disappear
# kill the application
# Store prepared config to ~/.local/share/JetBrains/Toolbox/
# Move ~/.local/share/JetBrains/Toolbox to ${pkdir}/${homedir}/.local/share/JetBrains/Toolbox

# install -d -m755 ~/.local/share/JetBrains/self-extractor
# mv jetbrains-toolbox "${pkgdir}/.local/share/JetBrains/self-extractor"

_apt_action="$1"

# shellcheck disable=SC2086
prepare() {
  set +x
  local _app_pid
  local _process_re='.*\./jetbrains-toolbox.*--wait-for-pid'

  _ensure_install_dir_not_exists

  ./jetbrains-toolbox --minimize &
  # > /tmp/jetbrains-toolbox-setup.log 2>&1

  # Seems like the _wait_and_return_pid call confuses jetbrains-toolbox's
  # check for a single instance, so let's wait a bit to skip that:
  printf 'I: Extracting and installing (please wait - takes some time!) ...\n'
  sleep 6

  _app_pid=$(_wait_and_return_pid "$_process_re")
  printf 'D: toolbox PID=[%s]\n' $_app_pid

  # Waiting for the .settings file to appear
  # while ! ps ax | grep -q './jetbrains-toolbox'; do sleep 0.2; done
  # _wait_until_gogo

  _wait_until_extraction_ends $_app_pid

  printf 'D: Terminating toolbox PID=[%s] ...' $_app_pid
  kill $_app_pid > /tmp/jetbrains-toolbox-setup.log 2>&1
  _wait_for_pid_to_die "$_process_re" $_app_pid
  printf ' Done.\n'

  # TODO: Remove V
  # Try again in case we've got something else above:
  # _app_pid=$(_wait_and_return_pid "$_process_re")
  # [ -n "$_app_pid" ] && {
  #   printf 'D: Terminating also toolbox PID=[%s] ...' $_app_pid
  #   kill $_app_pid > /tmp/jetbrains-toolbox-setup.log 2>&1
  #   _wait_for_pid_to_die "$_process_re" $_app_pid
  #   printf ' Done.\n'
  # }

  # _wait_for_pid_to_die "$_process_re" $_app_pid

  # printf 'D: _app_pid=[%s] stopped.\n' $_app_pid

  # Wait unti /tmp/gogo
  # _wait_until_gogo

  #_wait_extractor_pid
  # _kill_running_instance
  set -x
}

_wait_until_extraction_ends() {
  local _app_pid=$1
  local _regex='Calculating directory size at .+ done:'
  local logfile_path="${homedir}/.local/share/JetBrains/Toolbox/logs/toolbox.log"

  # Timeout 240 * 0.5s = 120s
  for i in {0..240}; do
    if [ -e "$logfile_path" ] && tail -2 "$logfile_path" | grep -Eq "$_regex"; then
      echo 'I: Toolbox Logfile marker detected.'
      sleep 4
      echo 'I: Toolbox self-extraction finished.'
      return
    else
      sleep 0.5
    fi
  done

  # shellcheck disable=SC2086
  kill -9 $_app_pid > /dev/null 2>&1
  printf 'E: TIMEOUT waiting for extraction to end, terminating\n' > /dev/stderr

  exit 12
}

_ensure_install_dir_not_exists() {
  # TODO: Consider this to be "${homedir}"/.local/share/JetBrains/Toolbox

  local _target_dir="${homedir}"/.local/share/JetBrains

  printf 'D: Ensure main dir does not exist: %s\n' "$_target_dir"

  # We need to first do this check as if a broken link has been left,
  # -e reports it does not exist :/
  [ -h "$_target_dir" ] && rm -f "$_target_dir"

  ! [ -e "$_target_dir" ] && return

  [ -d "$_target_dir" ] && rmdir --ignore-fail-on-non-empty "$_target_dir"

  if [ -h "$_target_dir" ] || [ -e "$_target_dir" ]; then
    printf 'E: FATAL: Target directory path exists: %s\n' "$_target_dir"
    exit 11
  fi
}

package() {
  set -x

  sudo rm -rf "${pkgdir}/${homedir}"/{*,.*} # in case there are leftovers

  # local credentials="-u '${USER}' -g '${USER}'"
  local cred=(-o "${USER}" -g "${USER}")

  sudo install -d "${cred[@]}" -m755 "${pkgdir}/${homedir}"/.local/share/JetBrains/
  sudo install -d "${cred[@]}" -m755 "${pkgdir}/${homedir}"/.local/share/applications/
  sudo install -d "${cred[@]}" -m755 "${pkgdir}/${homedir}"/.config/autostart/

  mv "${homedir}"/.local/share/JetBrains/Toolbox "${pkgdir}/${homedir}"/.local/share/JetBrains/
  mv "${homedir}"/.local/share/applications/jetbrains-toolbox.desktop "${pkgdir}/${homedir}"/.local/share/applications/
  mv -f ~/.config/autostart/jetbrains-toolbox.desktop "${pkgdir}/${homedir}"/.config/autostart/

  # TODO: Copt custom settings to
  # TODO: Create directories for apps and scripts
  # TODO: Deal with scripts needed in PATH
  set +x

  # _wait_until_gogo
}

post_install() {
  echo "
**IMPORTANT:**

  1. REBOOT: You need to reboot your machine to make sure any leftovers in /tmp
        and elsewere created by the app image (which does self-extraction,
        automamtic installation and what not) are removed. The app may segfault
        if this is not done.

  2. Complete the setup
    
     # TODO: Explain about setting NOT recommended to change
     # TODO: Explain about removing the package.
     # TODO: Provide URL to an .md file on Github where this info
     #       can be found - ask the guy to bookmark it.

     Start the Jetbrains Toolbox using your DE menu, or execute this command:

     $ "${homedir}"/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox

     then complete the configuration. Make sure your scripts path is included
     into your PATH; "${homedir}"/.local/bin is a good location (IMHO).

     # TODO: Provide a URL to a README

  Enjoy ;)
"
}

post_remove() {
  # TODO: terminate the application
  # TODO: Check the current stash
  printf 'D: _apt_action=[%s]' "$_apt_action"

  rm -f \
    "${homedir}"/.local/share/applications/jetbrains-toolbox.desktop \
    "${homedir}"/.config/autostart/jetbrains-toolbox.desktop

  rm -rf "${homedir}"/.cache/JetBrains/Toolbox

  echo "
**IMPORTANT:**

  1. REBOOT: You need to reboot your machine to make sure any leftovers in /tmp
        and elsewere created by the app image.

  2. To make sure you don't have any leftovers, run this:

     $ find ~ -iname '*toolbox*' 2>/dev/null

  Cheers ;)
  "
}

# _wait_until_gogo() {
#   echo "@@@@@@ Waiting until /tmp/gogo for you to check ${pkgdir}/${homedir}/.local/share/JetBrains/ ..."

#   while ! [ -e /tmp/gogo ]; do sleep 0.5; done
#   rm -f /tmp/gogo
# }

_wait_and_return_pid() {
  # local pid_to_wait
  # pid_to_wait=$(ps ax | awk '/jetbrains-toolbox[ \t]+--wait-for-pid/ && ! /awk/ {print $7}' | head -1)

  # [ -z "$pid_to_wait" ] && {
  #   printf 'E: Cound NOT get proper pid_to_wait: [$%s], terminating' "$pid_to_wait"
  #   exit 11
  # }

  # printf "I: Waiting for PID=[%s]..." "$pid_to_wait"
  # while ps ax | awk '{print $1}' | grep -q "$pid_to_wait"; do
  #   sleep 0.2
  # done
  # printf " Done.\n"

  local _command="$1"
  local _pid

  # Timeout 50 * 0.2s = 10s
  for i in {1..50}; do
    pgrep -f "$_command" > /dev/null 2>&1 && break
    sleep 0.2
  done

  _pid=$(pgrep -fo "$_command")

  # shellcheck disable=SC2086
  [ -z $_pid ] && {
    printf 'E: TIMEOUT waiting for PID of [%s], terminating\n' "$_command" > /dev/stderr
    exit 12
  }

  # shellcheck disable=SC2086
  printf '%s' $_pid
}

_wait_for_pid_to_die() {
  local _command="$1"
  local _pid=$2

  for i in {1..50}; do
    # shellcheck disable=SC2086
    if ! pgrep -fo "$_command" | grep -q $_pid; then
      return
    else
      sleep 0.2
    fi
  done

  printf 'E: TIMEOUT waiting for PID of [%s] to die, terminating\n' "$_pid" > /dev/stderr
  exit 12
}

_kill_running_instance() {
  local pid_to_kill
  pid_to_kill=$(ps ax | awk '/jetbrains-toolbox --wait-for-pid/ && ! /awk/ {print $1}' | sort | head -1)

  [ -z "$pid_to_kill" ] && {
    printf 'E: Cound NOT get proper pid_to_kill: [$%s], terminating\n' "$pid_to_kill"
    exit 11
  }

  printf 'I: Killing the self-extractor (PID=[%s])...' "$pid_to_kill"
  kill pid_to_kill

  while ps ax | awk '{print $1}' | grep -q "$pid_to_kill"; do
    sleep 0.2
  done
  printf " Done.\n"
}
