#!/bin/bash
# Checks DNS, GitHub Pages, HTTPS and redirects for doublehound.com.
# Run from anywhere: bash check-site.sh   (paste the whole output to Claude)

D=doublehound.com
ALT=doublehoundgames.com
REPO=davidjheberle/doublehound-site

ok()   { printf '  \033[32mOK\033[0m    %s\n' "$1"; }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$1"; }
info() { printf '  ..    %s\n' "$1"; }
code() { curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 15 "$1"; }

echo "== DNS ($D)"
A=$(dig +short $D A @1.1.1.1 | sort | tr '\n' ' ')
[ "$A" = "185.199.108.153 185.199.109.153 185.199.110.153 185.199.111.153 " ] && ok "A records: $A" || bad "A records: $A"
AAAA=$(dig +short $D AAAA @1.1.1.1 | sort | tr '\n' ' ')
[ "$(echo $AAAA | wc -w)" -eq 4 ] && ok "AAAA records: $AAAA" || bad "AAAA records: $AAAA"
W=$(dig +short www.$D CNAME @1.1.1.1)
[ "$W" = "davidjheberle.github.io." ] && ok "www CNAME: $W" || bad "www CNAME: $W"
info "MX (email): $(dig +short $D MX @1.1.1.1 | tr '\n' ' ')"
info "TXT: $(dig +short $D TXT @1.1.1.1 | tr '\n' ' ')"
info "_dmarc TXT: $(dig +short _dmarc.$D TXT @1.1.1.1 | tr '\n' ' ')"
info "Nameservers: $(dig +short $D NS @1.1.1.1 | tr '\n' ' ')"
V=$(dig +short _github-pages-challenge-davidjheberle.$D TXT @1.1.1.1)
[ -n "$V" ] && ok "GitHub verification TXT present" || info "GitHub verification TXT not found (optional step)"

echo "== HTTPS certificate"
CERT=$(echo | openssl s_client -connect $D:443 -servername $D 2>/dev/null | openssl x509 -noout -subject -issuer -enddate 2>/dev/null)
if echo "$CERT" | grep -q "$D"; then ok "certificate for $D"; echo "$CERT" | sed 's/^/        /'
else bad "no valid certificate for $D yet (GitHub issues it after the DNS check passes)"; fi

echo "== Pages"
check() { # url expected_code [expected_redirect_prefix]
  R=$(code "$1"); C=${R%% *}; L=${R#* }
  if [ "$C" = "$2" ] && { [ -z "$3" ] || [[ "$L" == $3* ]]; }; then ok "$1 -> $R"; else bad "$1 -> $R (expected $2 ${3:-})"; fi
}
check "https://$D/" 200
check "https://$D/go-chess/privacy/" 200
check "https://$D/go-chess/privacy" 301 "https://$D/go-chess/privacy/"
check "https://$D/no-such-page" 404
check "http://$D/" 301 "https://$D/"
check "https://www.$D/" 301 "https://$D/"
check "https://davidjheberle.github.io/doublehound-site/" 301 "https://$D/"
check "https://$D/status" 301 "https://$D/status/"
curl -s --max-time 15 "https://$D/status/" | grep -q 'url=https://stats.uptimerobot.com/JvniPlppvL' \
  && ok "/status/ redirects to the UptimeRobot status page" || bad "/status/ redirect to UptimeRobot missing"
curl -s --max-time 15 "https://$D/go-chess/privacy/" | grep -q 'id="deleting-your-account"' \
  && ok "#deleting-your-account anchor present" || bad "#deleting-your-account anchor missing"

echo "== Redirect domain ($ALT)"
info "A: $(dig +short $ALT A @1.1.1.1 | tr '\n' ' ')  www: $(dig +short www.$ALT @1.1.1.1 | tr '\n' ' ')"
info "MX (email): $(dig +short $ALT MX @1.1.1.1 | tr '\n' ' ')"
info "Nameservers: $(dig +short $ALT NS @1.1.1.1 | tr '\n' ' ')"
check "http://$ALT/" 301 "https://$D"
check "http://www.$ALT/" 301 "https://$D"

if command -v gh >/dev/null 2>&1; then
  echo "== GitHub Pages settings (gh)"
  gh api repos/$REPO/pages --jq '"  ..    source: \(.source.branch)\(.source.path)  cname: \(.cname)  https_enforced: \(.https_enforced)  status: \(.status)  cert: \(.https_certificate.state // "none")"' 2>&1
  gh api repos/$REPO/pages/health --jq 'if .domain == null then "  ..    health: GitHub is still computing it, run again in a minute" else "  ..    health: dns_resolves=\(.domain.dns_resolves) served_by_pages=\(.domain.is_served_by_pages) https_eligible=\(.domain.is_https_eligible) caa_error=\(.domain.caa_error)" end' 2>&1
else
  echo "== GitHub Pages settings: skipped (install the GitHub CLI with 'brew install gh' to include them)"
fi
