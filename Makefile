OODA_COMPILER ?= $(HOME)/.openooda/bin/oodac
OODACODEX ?= $(HOME)/.openooda/northstar.oot
OO_LIST_AMBIENT_QUOTA ?= 8589934592
BIN := dist/ootree

PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

SRC := $(wildcard *.oo) $(wildcard */*.oo)
VERSION ?= 0.2.0

.PHONY: build check line-cap file-law academy density verify clean test bench package package-deb package-rpm package-arch install uninstall

build: $(BIN)

$(BIN): $(SRC)
	@mkdir -p dist .ooda-cache/ooda-tmp
	OO_LIST_AMBIENT_QUOTA=$(OO_LIST_AMBIENT_QUOTA) OODACODEX=$(OODACODEX) OODA_COMPILER=$(OODA_COMPILER) OODA_NO_JAIL=1 $(OODA_COMPILER) build main.oo -o $(BIN)
	@chmod +x $(BIN)
	@cp -a $(BIN) dist/ootree-linux-x86_64
	@sha256sum dist/ootree-linux-x86_64 > dist/ootree-linux-x86_64.sha256
	@echo "built $(BIN) (and dist/ootree-linux-x86_64)"

# --- Verification gate ---------------------------------------------------------

line-cap:
	@violations=0; \
	for f in $$(find . -name "*.oo" -o -name "*.oot"); do \
		n=$$(wc -l < "$$f"); \
		if [ $$n -gt 256 ]; then \
			echo "VIOLATION: $$f = $$n lines (exceeds 256)"; violations=$$((violations+1)); \
			continue; \
		fi; \
		if [ $$n -lt 16 ]; then \
			echo "VIOLATION: $$f = $$n lines (under 16-line floor)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations files violate the Page Rule"; exit 1; fi; \
	echo "PASS: Page Rule sizing (16-256 lines on all files) holds"

file-law:
	@forbidden="py js ts rb pl json yaml toml"; \
	violations=0; \
	for ext in $$forbidden; do \
		found=$$(find . -name "*.$$ext" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null | head -3); \
		if [ -n "$$found" ]; then \
			echo "VIOLATION: .$$ext forbidden:"; echo "$$found"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.md" -not -path "./.git/*" -not -path "./.github/*" -not -path "./dist/*" -not -path "./.ooda-cache/*" 2>/dev/null); do \
		if [ "$$f" != "./README.md" ] && [ "$$f" != "./AGENTS.md" ]; then \
			echo "VIOLATION: .md forbidden outside README.md and AGENTS.md: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	for f in $$(find . -name "*.sh" -not -path "./.git/*" -not -path "./dist/*" 2>/dev/null); do \
		if [ "$$f" != "./install.sh" ] && [ "$$f" != "./uninstall.sh" ]; then \
			echo "VIOLATION: .sh forbidden outside install.sh and uninstall.sh: $$f"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: file-law violations"; exit 1; fi; \
	echo "PASS: file law holds"

academy:
	@failures=0; \
	for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		header=$$(head -7 "$$f"); \
		missing=""; \
		echo "$$header" | grep -q "^// # "        || missing="$$missing title"; \
		echo "$$header" | grep -q "^// Logline:"  || missing="$$missing logline"; \
		echo "$$header" | grep -q "^// Setup:"    || missing="$$missing setup"; \
		echo "$$header" | grep -q "^// Beats:"    || missing="$$missing beats"; \
		if [ -n "$$missing" ]; then \
			echo "FAIL: $$f missing Academy element(s):$$missing"; failures=$$((failures+1)); \
		fi; \
	done; \
	if [ $$failures -gt 0 ]; then echo "FAIL: $$failures academy header violations"; exit 1; fi; \
	echo "PASS: academy headers hold (all 4 elements present in first 7 lines)"

density:
	@violations=0; \
	for d in $$(find . -type d -not -path "./.git*" -not -path "./dist*" -not -path "./.ooda-cache*" -not -path "./packaging*"); do \
		n=$$(ls "$$d"/*.oo "$$d"/*.oot 2>/dev/null | grep -v '\*' | wc -l); \
		if [ $$n -gt 8 ]; then \
			echo "VIOLATION: $$d holds $$n pages (exceeds 8)"; violations=$$((violations+1)); \
		fi; \
	done; \
	if [ $$violations -gt 0 ]; then echo "FAIL: $$violations directories exceed the density bound"; exit 1; fi; \
	echo "PASS: directory density (<= 8 pages per directory) holds"

check:
	@for f in $$(find . -name "*.oo" -not -path "./dist/*"); do \
		$(OODA_COMPILER) check "$$f" > /dev/null || exit 1; \
	done; \
	echo "PASS: oodac check holds on all .oo files"

verify: line-cap file-law academy density check

test: $(BIN)
	@echo "=== Tier 1: Core CLI Flags, Options, Formats & Glyphs ==="
	@./$(BIN) --help > /dev/null && echo "PASS: --help"
	@./$(BIN) -h > /dev/null && echo "PASS: -h"
	@./$(BIN) --version | grep -q "0.2.0" && echo "PASS: --version"
	@./$(BIN) -v | grep -q "0.2.0" && echo "PASS: -v"
	@./$(BIN) --help | grep -q -- "-A" && echo "PASS: --help documents -A"
	@./$(BIN) --help | grep -q -- "--ascii" && echo "PASS: --help documents --ascii"
	@./$(BIN) --help | grep -q -- "--no-color" && echo "PASS: --help documents --no-color"
	@./$(BIN) --help | grep -q -- "--json" && echo "PASS: --help documents --json"
	@./$(BIN) --help | grep -q -- "--full-path" && echo "PASS: --help documents --full-path"
	@./$(BIN) --help | grep -q -- "--theme" && echo "PASS: --help documents --theme"
	@./$(BIN) tree | grep -q "scan.oo" && echo "PASS: basic tree traversal"
	@./$(BIN) -s tree | grep -q "\\[" && echo "PASS: size badge format"
	@./$(BIN) -d tree | grep -q "directories" && echo "PASS: directories only"
	@./$(BIN) -L 1 tree | grep -q "files" && echo "PASS: depth limit"
	@./$(BIN) -A tree | grep -q "\\\\--" && echo "PASS: ASCII branch glyphs"
	@./$(BIN) --ascii tree | grep -q "|--" && echo "PASS: --ascii branch glyphs"
	@./$(BIN) --no-color tree | grep -q "scan.oo" && echo "PASS: --no-color plain text"
	@ESC=$$(printf '\033'); ! (./$(BIN) --no-color tree | grep -q "$$ESC") && echo "PASS: --no-color suppresses all ANSI escapes"
	@./$(BIN) -f tree | grep -q "tree/scan.oo" && echo "PASS: -f full path"
	@./$(BIN) --full-path tree | grep -q "tree/anchor.oo" && echo "PASS: --full-path"
	@./$(BIN) --json tree | grep -q '"total_bytes":' && echo "PASS: --json total_bytes"
	@./$(BIN) --json tree | grep -q '"directories":' && echo "PASS: --json directories"
	@./$(BIN) --theme dracula tree | grep -q "files" && echo "PASS: --theme dracula override"
	@./$(BIN) --theme cyberpunk tree | grep -q "files" && echo "PASS: --theme cyberpunk override"
	@./$(BIN) --theme amber tree | grep -q "files" && echo "PASS: --theme amber override"
	@./$(BIN) non_existent_directory_xyz_123 2>&1 | grep -q "No such file" && echo "PASS: non-existent directory error output"
	@echo "=== Tier 2: MCP Handshake & Protocol Framing ==="
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q "2024-11-05" && echo "PASS: MCP initialize protocolVersion"
	@printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}\n' | ./$(BIN) --mcp | grep -q '"name":"ootree","version":"0.2.0"' && echo "PASS: MCP initialize serverInfo"
	@printf '{"jsonrpc":"2.0","id":2,"method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -q '"result":{}' && echo "PASS: MCP ping"
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "tree_structure" && echo "PASS: MCP tools/list tree_structure"
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "tree_summary" && echo "PASS: MCP tools/list tree_summary"
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "find_entries" && echo "PASS: MCP tools/list find_entries"
	@printf '{"jsonrpc":"2.0","id":3,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp | grep -q "directory_capacity" && echo "PASS: MCP tools/list directory_capacity"
	@test -z "$$(printf '{"jsonrpc":"2.0","method":"notifications/initialized","params":{}}\n' | ./$(BIN) --mcp)" && echo "PASS: MCP notifications/initialized produces no response"
	@printf '{"jsonrpc":"2.0","id":4,"method":"shutdown","params":{}}\n' | ./$(BIN) --mcp | grep -q '"result":null' && echo "PASS: MCP shutdown"
	@test -z "$$(printf '{"jsonrpc":"2.0","method":"exit","params":{}}\n' | ./$(BIN) --mcp)" && echo "PASS: MCP exit terminates cleanly"
	@test "$$(printf '{"jsonrpc":"2.0","id":1,"method":"ping","params":{}}{"jsonrpc":"2.0","id":2,"method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -c '"result":{}')" = "2" && echo "PASS: MCP concatenated JSON-RPC messages without newline"
	@printf '{"jsonrpc":"2.0","id":99,"method":"ping","params":{}}' | ./$(BIN) --mcp | grep -q '"id":99' && echo "PASS: MCP request without trailing newline"
	@(sleep 0.1 && printf '{"jsonrpc":"2.0","id":15,"method":"ping","params":{}}\n') | ./$(BIN) --mcp | grep -q '"result":{}' && echo "PASS: MCP stdio idle pause does not crash server"
	@echo "=== Tier 3: All 4 MCP Tools & Execution Edge Cases ==="
	@printf '{"jsonrpc":"2.0","id":10,"method":"tools/call","params":{"name":"tree_structure","arguments":{"path":"tree"}}}\n' | ./$(BIN) --mcp | grep -q 'scan.oo' && echo "PASS: MCP tree_structure default"
	@printf '{"jsonrpc":"2.0","id":11,"method":"tools/call","params":{"name":"tree_structure","arguments":{"path":"tree","ascii":true}}}\n' | ./$(BIN) --mcp | grep -q '|--' && echo "PASS: MCP tree_structure ASCII glyphs"
	@printf '{"jsonrpc":"2.0","id":12,"method":"tools/call","params":{"name":"tree_summary","arguments":{"path":"tree"}}}\n' | ./$(BIN) --mcp | grep -q 'files' && echo "PASS: MCP tree_summary files count"
	@printf '{"jsonrpc":"2.0","id":13,"method":"tools/call","params":{"name":"tree_summary","arguments":{"path":"tree"}}}\n' | ./$(BIN) --mcp | grep -q 'total_bytes' && echo "PASS: MCP tree_summary total_bytes"
	@printf '{"jsonrpc":"2.0","id":14,"method":"tools/call","params":{"name":"find_entries","arguments":{"path":"tree","pattern":"scan"}}}\n' | ./$(BIN) --mcp | grep -q 'tree/scan.oo' && echo "PASS: MCP find_entries match"
	@printf '{"jsonrpc":"2.0","id":15,"method":"tools/call","params":{"name":"find_entries","arguments":{"path":"tree","pattern":"nonexistent_xyz"}}}\n' | ./$(BIN) --mcp | grep -q 'count' && echo "PASS: MCP find_entries empty match"
	@printf '{"jsonrpc":"2.0","id":16,"method":"tools/call","params":{"name":"directory_capacity","arguments":{"path":"tree"}}}\n' | ./$(BIN) --mcp | grep -q 'formatted_size' && echo "PASS: MCP directory_capacity formatted_size"
	@printf '{"jsonrpc":"2.0","id":17,"method":"tools/call","params":{"name":"directory_capacity","arguments":{"path":"tree"}}}\n' | ./$(BIN) --mcp | grep -q 'avg_file_bytes' && echo "PASS: MCP directory_capacity avg_file_bytes"
	@echo "=== Tier 4: Negative Trust & Error Responses & Determinism & Smoke ==="
	@printf 'invalid json string\n' | ./$(BIN) --mcp | grep -q -- "-32600" && echo "PASS: MCP invalid json exits -32600"
	@printf '{"jsonrpc":"1.0","id":30,"method":"ping","params":{}}\n' | ./$(BIN) --mcp | grep -q -- "-32600" && echo "PASS: MCP invalid jsonrpc version exits -32600"
	@printf '{"jsonrpc":"2.0","id":31,"method":"","params":{}}\n' | ./$(BIN) --mcp | grep -q -- "-32600" && echo "PASS: MCP empty method exits -32600"
	@printf '{"jsonrpc":"2.0","id":32,"method":"nonexistent_method","params":{}}\n' | ./$(BIN) --mcp | grep -q -- "-32601" && echo "PASS: MCP unknown method exits -32601"
	@printf '{"jsonrpc":"2.0","id":33,"method":"tools/call","params":{"name":"nonexistent_tool","arguments":{}}}\n' | ./$(BIN) --mcp | grep -q -- "-32601" && echo "PASS: MCP unknown tool exits -32601"
	@printf '{"jsonrpc":"2.0","id":34,"method":"tools/call","params":{"name":"find_entries","arguments":{"path":"tree"}}}\n' | ./$(BIN) --mcp | grep -q -- "-32602" && echo "PASS: MCP find_entries missing pattern exits -32602"
	@run1="$$(printf '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp)"; \
	run2="$$(printf '{"jsonrpc":"2.0","id":1,"method":"tools/list","params":{}}\n' | ./$(BIN) --mcp)"; \
	test "$$run1" = "$$run2" && echo "PASS: determinism tools/list Run_1 == Run_2"
	@run1="$$(printf '{"jsonrpc":"2.0","id":7,"method":"ping","params":{}}\n' | ./$(BIN) --mcp)"; \
	run2="$$(printf '{"jsonrpc":"2.0","id":7,"method":"ping","params":{}}\n' | ./$(BIN) --mcp)"; \
	test "$$run1" = "$$run2" && echo "PASS: determinism ping Run_1 == Run_2"
	@./$(BIN) --json tree > .ooda-cache/run1.txt 2>&1; \
	./$(BIN) --json tree > .ooda-cache/run2.txt 2>&1; \
	diff -u .ooda-cache/run1.txt .ooda-cache/run2.txt && echo "PASS: double-run output is identical"
	@./install.sh --dry-run > /dev/null && echo "PASS: install.sh --dry-run"
	@./install.sh --uninstall --dry-run > /dev/null && echo "PASS: install.sh --uninstall --dry-run"
	@./uninstall.sh --dry-run > /dev/null && echo "PASS: uninstall.sh --dry-run"
	@echo "ALL TESTS PASSED"

bench: $(BIN)
	@echo "=== Running ootree performance benchmarks ==="
	@echo "--- CLI tree traversal benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 30); do ./$(BIN) tree > /dev/null; done'
	@echo "--- CLI json benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 30); do ./$(BIN) --json tree > /dev/null; done'
	@echo "--- MCP tree_structure benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 30); do printf '\''{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"tree_structure","arguments":{"path":"tree"}}}\n'\'' | ./$(BIN) --mcp > /dev/null; done'
	@echo "--- MCP tree_summary benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 50); do printf '\''{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"tree_summary","arguments":{"path":"tree"}}}\n'\'' | ./$(BIN) --mcp > /dev/null; done'
	@echo "--- MCP find_entries benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 50); do printf '\''{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"find_entries","arguments":{"path":"tree","pattern":"scan"}}}\n'\'' | ./$(BIN) --mcp > /dev/null; done'
	@echo "--- MCP directory_capacity benchmark ---"
	@time -p sh -c 'for i in $$(seq 1 50); do printf '\''{"jsonrpc":"2.0","id":4,"method":"tools/call","params":{"name":"directory_capacity","arguments":{"path":"tree"}}}\n'\'' | ./$(BIN) --mcp > /dev/null; done'
	@echo "Benchmark complete."

install: $(BIN)
	@mkdir -p $(DESTDIR)$(BINDIR)
	install -m 0755 $(BIN) $(DESTDIR)$(BINDIR)/ootree
	install -m 0755 uninstall.sh $(DESTDIR)$(BINDIR)/ootree-uninstall
	@echo "installed ootree and ootree-uninstall to $(DESTDIR)$(BINDIR)"

uninstall:
	@rm -f $(DESTDIR)$(BINDIR)/ootree $(DESTDIR)$(BINDIR)/ootree-uninstall
	@if [ "$(PURGE)" = "1" ]; then rm -rf $(HOME)/.cache/ootree $(HOME)/.config/ootree; echo "purged user cache and config"; fi
	@echo "uninstalled ootree and ootree-uninstall from $(DESTDIR)$(BINDIR)"

package-deb: $(BIN)
	@mkdir -p dist/deb-root/DEBIAN dist/deb-root/usr/bin
	@sed "s/^Version:.*/Version: $(VERSION)-1/" packaging/debian/control.binary > dist/deb-root/DEBIAN/control
	@cp $(BIN) dist/deb-root/usr/bin/ootree
	@chmod 0755 dist/deb-root/usr/bin/ootree
	@cp uninstall.sh dist/deb-root/usr/bin/ootree-uninstall
	@chmod 0755 dist/deb-root/usr/bin/ootree-uninstall
	@dpkg-deb --build --root-owner-group dist/deb-root dist/ootree_$(VERSION)-1_amd64.deb
	@rm -rf dist/deb-root
	@echo "built dist/ootree_$(VERSION)-1_amd64.deb"

package-rpm: $(BIN)
	@mkdir -p ~/rpmbuild/SOURCES ~/rpmbuild/SPECS ~/rpmbuild/RPMS
	@cp $(BIN) ~/rpmbuild/SOURCES/ootree-linux-x86_64
	@cp uninstall.sh ~/rpmbuild/SOURCES/uninstall.sh
	@sed "s/^Version:.*/Version: $(VERSION)/" packaging/ootree.spec > ~/rpmbuild/SPECS/ootree.spec
	@rpmbuild -bb ~/rpmbuild/SPECS/ootree.spec
	@cp ~/rpmbuild/RPMS/x86_64/ootree-$(VERSION)*.rpm dist/ 2>/dev/null || true
	@if ls dist/ootree-$(VERSION)-1.*.x86_64.rpm 1> /dev/null 2>&1; then cp dist/ootree-$(VERSION)-1.*.x86_64.rpm dist/ootree-$(VERSION)-1.x86_64.rpm; fi
	@echo "built dist RPM package"

package-arch: $(BIN)
	@mkdir -p dist/arch-pkg/usr/bin
	@cp $(BIN) dist/arch-pkg/usr/bin/ootree
	@chmod 0755 dist/arch-pkg/usr/bin/ootree
	@cp uninstall.sh dist/arch-pkg/usr/bin/ootree-uninstall
	@chmod 0755 dist/arch-pkg/usr/bin/ootree-uninstall
	@printf "pkgname = ootree\npkgbase = ootree\npkgver = $(VERSION)-1\npkgdesc = Sovereign directory hierarchy and tree visualizer\nurl = https://github.com/openOODA-tools/ootree\nbuilddate = $$(date +%s)\npackager = openOODA-tools <ops@openooda.org>\nsize = $$(stat -c %s $(BIN))\narch = x86_64\nlicense = Apache-2.0\ndepend = glibc\nprovides = ootree\n" > dist/arch-pkg/.PKGINFO
	@tar --zstd -cf dist/ootree-$(VERSION)-1-x86_64.pkg.tar.zst -C dist/arch-pkg .PKGINFO usr
	@rm -rf dist/arch-pkg
	@bash -n packaging/arch/PKGBUILD
	@cp packaging/arch/PKGBUILD dist/PKGBUILD
	@cp packaging/arch/PKGBUILD packaging/PKGBUILD
	@echo "built dist/ootree-$(VERSION)-1-x86_64.pkg.tar.zst and validated PKGBUILD"

package: package-deb package-rpm package-arch
	@cp $(BIN) dist/ootree-linux-x86_64
	@chmod 0755 dist/ootree-linux-x86_64
	@(cd dist && sha256sum ootree-linux-x86_64 > ootree-linux-x86_64.sha256)
	@(cd dist && sha256sum ootree* > checksums.txt)
	@echo "built all packages and generated dist/checksums.txt"

clean:
	@rm -rf dist .ooda-cache
	@echo "cleaned"
