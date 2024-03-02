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

# _repo_base_url='https://raw.githubusercontent.com/ya55en/pacstall-repo/main'
_repo_base_url='file:///home/ya55en/Work/Mine/pacstall-repo'
_apt_args=$*
_curent_user="$USER"

# shellcheck disable=SC2086
prepare() {
  local _app_pid
  local _process_re='.*\./jetbrains-toolbox.*--wait-for-pid'

  _ensure_install_dir_not_exists

  ./jetbrains-toolbox --minimize > /tmp/jetbrains-toolbox-setup.log 2>&1 &

  # Seems like the _wait_and_return_pid call confuses jetbrains-toolbox's
  # check for a single instance, so let's wait a bit to skip that:
  cat << EOS
I: Extracting and installing. Please, wait (takes some time!) ...
I: Meanwhile, the Toolbox may appear minimized as a tray icon - do NOT
I: open it yet or use the application - it is not fully installed. You
I: will do that later, after a *reboot* (instructions follow).
EOS

  sleep 6
  _app_pid=$(_wait_and_return_pid "$_process_re")
  printf 'D: toolbox PID=[%s]\n' $_app_pid

  _wait_extraction_end $_app_pid

  printf 'D: Terminating toolbox PID=[%s] ...' $_app_pid
  kill $_app_pid > /tmp/jetbrains-toolbox-setup.log 2>&1
  _wait_for_pid_to_die "$_process_re" $_app_pid
  printf ' Done.\n'
}

package() {
  local _cred=(-o "${_curent_user}" -g "${_curent_user}")

  # Make sure no leftovers from broken builds
  sudo rm -rf "${pkgdir}/{*,.*}" 2> /dev/null || true
  rm -f "$homedir"/.config/autostart/jetbrains-toolbox.desktop # no autostart by default
  printf 'D: Cleaned up %s.\n' "$pkgdir"

  # Download and store custom settings
  curl -sSLO "${_repo_base_url}/packages/jetbrains-toolbox-app/settings.json"
  chmod 664 settings.json
  printf 'D: Downloaded settings.json\n'

  mv -f \
    "${homedir}"/.local/share/JetBrains/Toolbox/.settings.json \
    "${homedir}"/.local/share/JetBrains/Toolbox/.settings.orig.json
  printf 'D: Moved original .settings.json\n'

  sudo install -m664 settings.json "${homedir}"/.local/share/JetBrains/Toolbox/.settings.json

  # Create directories
  sudo install -d "${_cred[@]}" -m750 "${pkgdir}/${homedir}"/.local/share/JetBrains/
  sudo install -d "${_cred[@]}" -m700 "${pkgdir}/${homedir}"/.local/share/applications/

  # Move installed product to $pkgdir
  mv "${homedir}"/.local/share/JetBrains/Toolbox "${pkgdir}/${homedir}"/.local/share/JetBrains/
  mv "${homedir}"/.local/share/applications/jetbrains-toolbox.desktop "${pkgdir}/${homedir}"/.local/share/applications/
}

post_install() {
  # local _cred=(-o "${_curent_user}" -g "${_curent_user}")
  local _main_dir="${homedir}/.local/share/JetBrains"

  # install -d "${_cred[@]}" -m750 "${homedir}"/.local/share/JetBrains/toolbox-apps
  # For some reason, install createas these with root:root ownership, no matter what,
  # so let's do it "the other way"(tm) ;)
  for subdir in toolbox-apps toolbox-scripts; do
    # shellcheck disable=SC2174
    mkdir -pm 750 "$_main_dir/$subdir"
  done

  # mkdir "$_the_dirs"
  # chown "$_curent_user":"$_curent_user" "$_the_dirs"
  # chmod 750 "$_the_dirs"

  _show_post_install_message
}

post_remove() {
  set -x
  local _full_dir

  printf 'D: _apt_args=[%s]\n' "$_apt_args"

  case "$_apt_args" in
    *purge*)
      printf 'D: PURGING: removing toolbox-apps, toolbox-scripts (and NO MESSAGE)\n'

      rm -rf "${homedir}"/.local/share/JetBrains/Toolbox

      for subdir in toolbox-apps toolbox-scripts; do
        _full_dir="${homedir}/.local/share/JetBrains/$subdir"
        rmdir --ignore-fail-on-non-empty "$_full_dir" 2> /tmp/jb.log || {
          printf 'post_remove(pacstall): directory %s not empty so not removed\n' "$_full_dir"
        }
      done
      ;;

    *remove*)
      printf 'D: REMOVE (explicit) - Trying to kill Toolbox\n'

      _kill_running_app
      ;;

    *)
      # remove and any other cases, like 'failed-upgrade' are here
      printf 'D: REMOVE (so message IS DUE)\n'

      printf 'D: Removing .desktop files...\n'
      rm -f \
        "${homedir}"/.local/share/applications/jetbrains-toolbox.desktop \
        "${homedir}"/.config/autostart/jetbrains-toolbox.desktop

      _show_post_remove_message
      ;;
      # *)
      #   set +x
      #   printf 'E: Unexpected apt-get command line: [%s], terminating\n' "$_apt_args"
      #   exit 12
      #   ;;
  esac

  set +x
}

## private

_show_post_install_message() {
  cat << EOS

**IMPORTANT:**

  1. REBOOT: You need to reboot your machine to make sure any leftovers in /tmp
        and elsewere created by the installer are removed. The app may segfault
        if this is not done.

  2. Complete the setup
        After the reboot (!), run the application from your Desktop Menu or
        with this command:

        $ "${homedir}"/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox

        Follow the wizard for setting it up (telemetry, accepting the License
        Agreement, chosse language). Then click the gear icon on top right to
        open the full-blooded "Settings" dialog.
        
        CAUTION: Do NOT switch on the auto-updates. Use pacstall to update the
        application. The built-in auto-update may break the package (will break
        version tracking for sure).

        Feel free to change the other options if you need to.

        Finally, make sure your scripts path is included into your PATH.
        Or feel free to change the default to '~/.local/bin' - seems like a
        good location.

  Enjoy ;)

EOS
}

_show_post_remove_message() {
  cat << EOS

**IMPORTANT:**

  1. REBOOT: You need to reboot your machine to make sure any leftovers in /tmp
        and elsewere created by the app image.

  2. To see if there are any leftovers, run this:

     $ find ~/ -iname '*toolbox*' 2>/dev/null

     Two known such locations you may want to check:
     - "${homedir}/.local/share/JetBrains/toolbox-apps
     - "${homedir}/.local/share/JetBrains/toolbox-scripts

  Cheers ;)

EOS
}

# shellcheck disable=SC2086
_kill_running_app() {
  local _app_pid
  _app_pid=$(pgrep -fo '^\.\/jetbrains-toolbox')

  printf 'D: _app_pid=[%s]\n' $_app_pid

  [ -n "$_app_pid" ] && {
    printf 'I: Toolbox is running, terminating (PID=[%s])' "$_app_pid"
    kill $_app_pid || true
  }
}

_wait_extraction_end() {
  local _app_pid=$1
  local _regex='Calculating directory size at .+ done:'
  local _logfile_path="${homedir}/.local/share/JetBrains/Toolbox/logs/toolbox.log"

  # Timeout 360 * 0.5s = 180s
  for i in {1..360}; do
    if [ -e "$_logfile_path" ] && tail -2 "$_logfile_path" | grep -Eq "$_regex"; then
      echo 'I: Toolbox Logfile marker detected: self-extraction ended.'
      sleep 4
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
  local _target_dir="${homedir}"/.local/share/JetBrains/Toolbox

  printf 'D: Ensure main dir does not exist: %s\n' "$_target_dir"

  # Remove a broken link. Need to first do this first as if a broken link is
  # there, `test -e` returns 1 (non-existent) but still cannot create the dir
  [ -h "$_target_dir" ] && ! [ -e "$_target_dir" ] && rm -f "$_target_dir"

  [ -d "$_target_dir" ] && rmdir --ignore-fail-on-non-empty "$_target_dir"

  ! [ -e "$_target_dir" ] && return

  printf 'E: FATAL: Target directory path exists: %s\n' "$_target_dir"
  exit 11
}

# shellcheck disable=SC2086
_wait_and_return_pid() {
  local _command="$1"
  local _pid

  # Timeout 50 * 0.2s = 10s
  for i in {1..50}; do
    pgrep -f "$_command" > /dev/null 2>&1 && break
    sleep 0.2
  done

  _pid=$(pgrep -fo "$_command")

  [ -z $_pid ] && {
    printf 'E: TIMEOUT waiting for PID of [%s], terminating\n' "$_command" > /dev/stderr
    exit 12
  }

  printf '%s' $_pid
}

_wait_for_pid_to_die() {
  local _command="$1"
  local _pid=$2

  for i in {1..50}; do
    if ! pgrep -fo "$_command" | grep -q $_pid; then
      return
    else
      sleep 0.2
    fi
  done

  printf 'E: TIMEOUT waiting for PID of [%s] to die, terminating\n' "$_pid" > /dev/stderr
  exit 12
}
