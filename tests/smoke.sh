#!/usr/bin/env bash
# Smoke test sysinfo — jalankan dari root repo: bash tests/smoke.sh
set -euo pipefail
cd "$(dirname "$0")/.."

PASS=0
FAIL=0
check() { # check "nama" "perintah..."
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        echo "FAIL: $name"; FAIL=$((FAIL+1))
    fi
}
check_contains() { # check_contains "nama" "jarum" "perintah..."
    # NB: grep tanpa -q supaya tidak menutup pipa lebih awal (SIGPIPE
    # + pipefail akan membuat cek yang jarumnya di awal output gagal).
    local name="$1" needle="$2"; shift 2
    if "$@" 2>/dev/null | grep -F "$needle" >/dev/null; then
        echo "PASS: $name"; PASS=$((PASS+1))
    else
        echo "FAIL: $name (tidak ada '$needle')"; FAIL=$((FAIL+1))
    fi
}
check_not_contains() {
    local name="$1" needle="$2"; shift 2
    if "$@" 2>/dev/null | grep -F "$needle" >/dev/null; then
        echo "FAIL: $name (masih ada '$needle')"; FAIL=$((FAIL+1))
    else
        echo "PASS: $name"; PASS=$((PASS+1))
    fi
}

# 1. Output manusia: semua seksi muncul.
check_contains "output manusia ada seksi OS"      "Sistem Operasi" ./sysinfo
check_contains "output manusia ada seksi CPU"     "CPU"            ./sysinfo
check_contains "output manusia ada seksi Memori"  "Memori"         ./sysinfo
check_contains "output manusia ada seksi Disk"    "Disk"           ./sysinfo
check_contains "output manusia ada seksi Jaringan" "Jaringan"      ./sysinfo

# 2. Nilai nyata: kernel + hostname beneran kebaca, bukan "unknown".
check_contains "kernel terdeteksi" "$(uname -r)" ./sysinfo
check_contains "hostname terdeteksi" "$(hostname)" ./sysinfo

# 3. JSON valid + semua kunci ada.
./sysinfo --json > /tmp/sysinfo-test.json
check "JSON valid (python3 json.tool)" python3 -m json.tool /tmp/sysinfo-test.json
check_contains "JSON punya kunci os"   '"os"'   cat /tmp/sysinfo-test.json
check_contains "JSON punya kunci cpu"  '"cpu"'  cat /tmp/sysinfo-test.json
check_contains "JSON punya kunci mem"  '"mem"'  cat /tmp/sysinfo-test.json
check_contains "JSON punya kunci disk" '"disk"' cat /tmp/sysinfo-test.json
check_contains "JSON punya kunci net"  '"net"'  cat /tmp/sysinfo-test.json
check_contains "JSON mem.total_bytes angka" '"total_bytes": ' cat /tmp/sysinfo-test.json

# 4. --section mem: hanya memori, JSON valid, kunci lain tidak ada.
./sysinfo --section mem --json > /tmp/sysinfo-mem.json
check "JSON --section mem valid" python3 -m json.tool /tmp/sysinfo-mem.json
check_contains "section mem ada kunci mem" '"mem"' cat /tmp/sysinfo-mem.json
check_not_contains "section mem tanpa kunci cpu" '"cpu"' cat /tmp/sysinfo-mem.json

# 5. --section cpu (manusia): hanya CPU.
check_contains "section cpu tampil" "CPU" ./sysinfo --section cpu
check_not_contains "section cpu tanpa Memori" "Memori" ./sysinfo --section cpu

# 6. Opsi salah -> exit bukan 0.
if ./sysinfo --section bogus >/dev/null 2>&1; then
    echo "FAIL: --section bogus harus gagal"; FAIL=$((FAIL+1))
else
    echo "PASS: --section bogus ditolak"; PASS=$((PASS+1))
fi
if ./sysinfo --tidak-ada >/dev/null 2>&1; then
    echo "FAIL: opsi tidak dikenal harus gagal"; FAIL=$((FAIL+1))
else
    echo "PASS: opsi tidak dikenal ditolak"; PASS=$((PASS+1))
fi

# 7. --help dan --version jalan.
check "--help exit 0" ./sysinfo --help
check "--version exit 0" ./sysinfo --version

echo
echo "Hasil: $PASS lulus, $FAIL gagal"
[[ $FAIL -eq 0 ]]
