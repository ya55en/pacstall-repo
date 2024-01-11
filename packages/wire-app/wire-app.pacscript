# shellcheck shell=bash disable=SC2034

name='wire-app'
pkgname='wire'
gives="${pkgname}"
repology=('project: wire')
breaks=("${pkgname}" "${pkgname}-deb" "${pkgname}-git" "${pkgname}-bin")
replace=("${pkgname}")
pkgver='3.32.3079'
url="https://github.com/wireapp/wire-desktop/releases/download/linux/${pkgver}/Wire-${pkgver}_x86_64.AppImage"
hash='4524855e263de813ff223512859673e465f8d2e75fd0f661d956d3de876601ef'
arch=('amd64')
maintainer='ya55en <ya55en.pacstall@gmail.com>'
homepage='https://wire.com/'
pkgdesc="A secure messenger with E2EE

Secure messaging for large groups that comes from one of the initiators of the
MLS standard and is ready for post-quantum security and interoperability.

Industry-leading, end-to-end encryption that's always activated to protect your
conversations, calls and shared documents.
"

package() {
  local REPO_BASE_URL='https://raw.githubusercontent.com/ya55en/pacstall-repo'

  sudo install -Dm755 "Wire-${pkgver}_x86_64.AppImage" "${pkgdir}/usr/local/bin/${pkgname}"

  curl -sSLO "$REPO_BASE_URL/main/packages/wire-app/com.wire.white-logo.png"
  sudo install -D -m755 com.wire.white-logo.png \
    "${pkgdir}/usr/share/icons/hicolor/256x256/pacstall/com.wire.white-logo.png"

  curl -sSLO "$REPO_BASE_URL/main/packages/wire-app/com.wire.desktop"
  sudo install -D -m755 com.wire.desktop \
    "${pkgdir}/usr/share/applications/pacstall/com.wire.desktop"
}

post_remove() {
  if [ -e "${homedir}/.config/Wire/" ]; then
    echo "Config and chat data remains in ${homedir}/.config/Wire/ -"
    echo "remove if not needed with:"
    echo "  rm -rf ${homedir}/.config/Wire/"
  fi
}
