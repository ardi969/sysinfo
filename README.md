# sysinfo

Laporan sistem **satu halaman** — OS, kernel, CPU, RAM, disk, jaringan —
dalam format manusia yang enak dibaca, atau JSON buat scripting.
Tanpa dependensi di luar tool standar Linux (`/proc`, `df`, `ip`).

```text
$ sysinfo
== Sistem Operasi ==
  Hostname:      myserver
  OS:            Ubuntu 24.04.5 LTS
  Kernel:        6.8.0-31-generic
  Arsitektur:    x86_64
  Uptime:        3 days 4 hours 12 minutes
== CPU ==
  Model:         AMD EPYC 9D25 126-Core Processor
  Core:          4
  Load avg:      0.12, 0.08, 0.05
== Memori ==
  RAM total:     7.8 GiB
  RAM terpakai:  6.6 GiB
  RAM tersedia:  1.0 GiB
  RAM bebas:     512.0 MiB
  Swap total:    1.0 GiB
  Swap terpakai: 0 B
== Disk ==
  MOUNT                     TOTAL   TERPAKAI   TERSEDIA   PAKAI
  /                        100.0 GiB   42.3 GiB   57.7 GiB    43%
== Jaringan ==
  eth0:          192.168.1.10/24
```

## Install

Tidak butuh install apa-apa — cukup `bash`, `awk`, `df`, dan `ip`
(biasanya sudah ada di semua distro Linux):

```bash
# pakai langsung
./sysinfo

# atau install ke PATH
sudo install -m 755 sysinfo /usr/local/bin/sysinfo
```

## Penggunaan

```bash
sysinfo                          # semua seksi, format manusia
sysinfo --json                   # semua seksi sebagai JSON
sysinfo --section mem            # hanya memori
sysinfo --section disk --json    # hanya disk, JSON
sysinfo --no-color               # tanpa warna (otomatis mati kalau di-pipe)
sysinfo --color                  # paksa warna meski output di-pipe
```

Seksi yang tersedia: `os`, `cpu`, `mem`, `disk`, `net`, `all` (default).

## Output JSON

```json
{
  "os": {"hostname": "myserver", "name": "Ubuntu 24.04.5 LTS", "kernel": "6.8.0-31-generic", "arch": "x86_64", "uptime": "3 days 4 hours 12 minutes"},
  "cpu": {"model": "AMD EPYC 9D25 126-Core Processor", "cores": 4, "load_avg": "0.12, 0.08, 0.05"},
  "mem": {"total_bytes": 8524517376, "used_bytes": 7130316800, "available_bytes": 1073741824, "free_bytes": 536870912, "swap_total_bytes": 1073741824, "swap_used_bytes": 0},
  "disk": [{"mount": "/", "size_bytes": 107374182400, "used_bytes": 45424435200, "available_bytes": 61949747200, "use_percent": "43%"}],
  "net": [{"interface": "eth0", "ipv4": "192.168.1.10/24"}]
}
```

Angka memori/disk dalam byte supaya gampang diolah script. Nilai `used`
pada RAM dihitung sebagai `total - available` (perkiraan yang biasa
dipakai `free`).

## Catatan

- **Hanya membaca:** `sysinfo` tidak mengubah apa pun di sistem.
- Disk: filesystem `tmpfs` dan `devtmpfs` dilewati supaya tabel tidak
  penuh entri yang tidak relevan.
- Jaringan: menampilkan IPv4 per interface (dari `ip -4 -brief addr`,
  fallback ke `hostname -I` kalau `ip` tidak ada). Interface loopback
  dilewati.
- Warna otomatis aktif hanya kalau output ke terminal; saat di-pipe
  atau di-redirect, warna mati sendiri.
- Diuji di Ubuntu 24.04 (VM) — lihat `tests/smoke.sh`.

## Test

```bash
bash tests/smoke.sh   # output manusia + JSON + --section + opsi salah
shellcheck sysinfo    # static analysis (0.10.0, bersih)
```

## Lisensi

MIT — lihat [LICENSE](LICENSE).
