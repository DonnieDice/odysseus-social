#!/usr/bin/env bash
set -euo pipefail

source scripts/ci/package-common.sh

version="$(odysseus_version)"
mkdir -p artifacts aur

cat > aur/PKGBUILD <<EOF
# Maintainer: Odysseus Maintainers <maintainers@example.invalid>
pkgname=odysseus-ai-workspace
pkgver=${version}
pkgrel=1
pkgdesc="Self-hosted AI workspace with chat, agents, research, documents, memory, email, calendar, and local tools"
arch=('x86_64')
url="https://github.com/DonnieDice/odysseus"
license=('MIT')
depends=('python>=3.11' 'python-pip' 'python-virtualenv')
makedepends=('git')
backup=('etc/odysseus/odysseus.env')
source=("\${pkgname}-\${pkgver}.tar.gz::https://github.com/DonnieDice/odysseus/archive/refs/tags/v\${pkgver}.tar.gz")
sha256sums=('SKIP')

package() {
  cd "\$srcdir/odysseus-\${pkgver}"
  install -dm755 "\$pkgdir/opt/odysseus"
  cp -a . "\$pkgdir/opt/odysseus/"
  install -Dm644 packaging/systemd/odysseus.service "\$pkgdir/usr/lib/systemd/system/odysseus.service"
  install -Dm644 packaging/odysseus.env.example "\$pkgdir/etc/odysseus/odysseus.env"
  install -dm755 "\$pkgdir/var/lib/odysseus" "\$pkgdir/var/log/odysseus"
}
EOF

(
  cd aur
  makepkg --printsrcinfo > .SRCINFO
  makepkg --source --nodeps --skipchecksums
)

cp aur/PKGBUILD aur/.SRCINFO artifacts/
cp aur/*.src.tar.gz artifacts/ 2>/dev/null || true
write_artifact_manifest artifacts
