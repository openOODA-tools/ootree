Name:           ootree
Version:        0.2.0
Release:        1%{?dist}
Summary:        Sovereign directory hierarchy and tree visualizer
License:        ASL 2.0
URL:            https://github.com/openOODA-tools/ootree
Source0:        ootree-linux-x86_64
Source1:        uninstall.sh
BuildArch:      x86_64
Requires:       glibc

%description
ootree is a sovereign directory hierarchy and tree visualizer written in pure
openOODA, featuring Unicode and ASCII branch glyphs, human-readable size badges,
theme integration, JSON export, and a high-performance MCP stdio server.

%install
mkdir -p %{buildroot}/usr/bin
install -m 0755 %{SOURCE0} %{buildroot}/usr/bin/ootree
install -m 0755 %{SOURCE1} %{buildroot}/usr/bin/ootree-uninstall

%files
/usr/bin/ootree
/usr/bin/ootree-uninstall

%changelog
* Wed Oct 07 2026 openOODA-tools <ops@openooda.org> - 0.2.0-1
- Sovereign elevation: streaming object-boundary MCP framing, 4 MCP tools, ASCII glyphs, and JSON export

* Wed Oct 07 2026 openOODA-tools <ops@openooda.org> - 0.1.0-1
- Initial sovereign release
