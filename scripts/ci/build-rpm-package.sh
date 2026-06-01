#!/usr/bin/env bash
set -euo pipefail

source scripts/ci/package-common.sh

target="${1:?usage: build-rpm-package.sh <target-suffix>}"
version="$(odysseus_version)"
topdir="${PWD}/.rpmbuild"
archive_dir="${topdir}/SOURCES"
build_name="odysseus-${version}"

rm -rf "$topdir"
mkdir -p "$topdir"/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
git archive --format=tar.gz --prefix="${build_name}/" -o "${archive_dir}/${build_name}.tar.gz" HEAD

cat > "${topdir}/SPECS/odysseus-ai-workspace.spec" <<EOF
Name:           odysseus-ai-workspace
Version:        ${version}
Release:        1%{?dist}
Summary:        Self-hosted AI workspace
License:        MIT
URL:            https://github.com/DonnieDice/odysseus
Source0:        ${build_name}.tar.gz
BuildArch:      noarch
Requires:       python3 >= 3.11
Requires:       python3-pip
Requires:       systemd

%description
Odysseus provides a self-hosted AI workspace with chat, agents, research,
documents, memory, email, calendar, and local tools.

%prep
%autosetup -n ${build_name}

%build

%install
mkdir -p %{buildroot}/opt/odysseus
cp -a . %{buildroot}/opt/odysseus/
install -Dm0644 packaging/systemd/odysseus.service %{buildroot}%{_unitdir}/odysseus.service
install -Dm0644 packaging/odysseus.env.example %{buildroot}%{_sysconfdir}/odysseus/odysseus.env
mkdir -p %{buildroot}%{_sharedstatedir}/odysseus %{buildroot}%{_localstatedir}/log/odysseus

%post
getent group odysseus >/dev/null || groupadd -r odysseus
getent passwd odysseus >/dev/null || useradd -r -g odysseus -d %{_sharedstatedir}/odysseus -s /sbin/nologin odysseus
chown -R odysseus:odysseus %{_sharedstatedir}/odysseus %{_localstatedir}/log/odysseus || true
python3 -m venv /opt/odysseus/.venv || true
/opt/odysseus/.venv/bin/python -m pip install --upgrade pip || true
/opt/odysseus/.venv/bin/python -m pip install -r /opt/odysseus/requirements.txt || true
%systemd_post odysseus.service

%preun
%systemd_preun odysseus.service

%postun
%systemd_postun_with_restart odysseus.service

%files
%license LICENSE
%doc README.md
/opt/odysseus
%config(noreplace) %{_sysconfdir}/odysseus/odysseus.env
%{_unitdir}/odysseus.service
%dir %{_sharedstatedir}/odysseus
%dir %{_localstatedir}/log/odysseus
EOF

rpmbuild --define "_topdir ${topdir}" -ba "${topdir}/SPECS/odysseus-ai-workspace.spec"
mkdir -p artifacts
find "${topdir}/RPMS" "${topdir}/SRPMS" -type f \( -name '*.rpm' -o -name '*.src.rpm' \) \
  -exec sh -c 'for f; do cp "$f" "artifacts/$(basename "$f" .rpm)-'"${target}"'.rpm"; done' sh {} +
write_artifact_manifest artifacts
