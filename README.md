# AI Coding Agent Setup

Repo ini berisi setup supaya terminal AI coding agent seperti CodeWhale atau DeepSeek-TUI bisa dipakai secara repeatable di beberapa device.

Tujuannya:

- Setelah `git clone` atau `git pull`, kamu cukup menjalankan satu script setup.
- API key tidak ikut ke-commit.
- Agent punya instruksi project di `.deepseek/skills/`.
- Agent punya folder standar untuk membaca PDF, Excel, dan CSV lokal di `docs-input/`.

## 1. Setup Pertama Kali

### Windows PowerShell

Masuk ke folder repo:

```powershell
cd C:\path\to\ai-agent-setup
```

Jalankan setup:

```powershell
.\setup.ps1
```

Kalau script membuat file `.env`, buka file itu lalu isi API key:

```text
DEEPSEEK_API_KEY=isi_api_key_kamu_di_sini
```

Setelah `.env` diisi, jalankan setup lagi:

```powershell
.\setup.ps1
```

Kalau sukses, script akan menampilkan command agent, biasanya:

```powershell
codewhale
```

### Linux, macOS, atau Git Bash

Masuk ke folder repo:

```bash
cd /path/ke/ai-agent-setup
```

Jalankan setup:

```bash
chmod +x setup.sh
./setup.sh
```

Isi `.env` kalau diminta, lalu jalankan ulang:

```bash
./setup.sh
```

## 2. Setelah Pull di Device Lain

Di device baru, lakukan:

```powershell
git clone <url-repo-ini>
cd ai-agent-setup
.\setup.ps1
```

Atau kalau repo sudah ada:

```powershell
cd C:\path\to\ai-agent-setup
git pull
.\setup.ps1
```

File `.env` memang tidak ikut git, jadi di setiap device kamu perlu mengisi API key lokal masing-masing.

## 3. Cara Menjalankan Agent

Jalankan agent dari folder repo yang ingin dibaca atau diedit.

Untuk repo ini:

```powershell
cd C:\path\to\ai-agent-setup
codewhale
```

Untuk repo lain:

```powershell
cd C:\path\to\target-repo
codewhale
```

Prinsipnya sederhana: agent membaca folder tempat kamu menjalankan command.

## 4. Cara Paling Praktis: Pakai Launcher

Repo ini menyediakan launcher supaya kamu bisa kasih path repo, lalu agent langsung scan awal.

Contoh untuk repo:

```text
C:\path\to\target-repo
```

Jalankan dari repo setup ini:

```powershell
cd C:\path\to\ai-agent-setup
.\agent.ps1 -Path "C:\path\to\target-repo"
```

Yang dilakukan launcher:

- Masuk ke folder target.
- Memakai skill dari repo setup ini lewat `CODEWHALE_SKILLS_DIR`.
- Tidak menyalin banyak file `SKILL.md` ke repo target secara default.
- Membuat `docs-input/` jika belum ada.
- Menambahkan ignore aman untuk `.env`, `docs-input/`, `.codewhale/state/`, dan `.deepseek/` di repo target.
- Menggunakan API key dari `.env` di repo setup ini untuk proses CodeWhale.
- Menjalankan CodeWhale dengan prompt scan repo dalam Bahasa Indonesia.

Secara default launcher menjalankan CodeWhale dengan one-shot prompt:

```powershell
codewhale --provider deepseek -p "<prompt scan repo>"
```

Kalau kamu ingin masuk mode chat interaktif, pakai:

```powershell
.\agent.ps1 -Path "C:\path\to\target-repo" -Interactive
```

Di mode interaktif, launcher akan menampilkan prompt pembuka. Paste prompt itu ke CodeWhale.

Kalau mau memberi tugas custom:

```powershell
.\agent.ps1 -Path "C:\path\to\target-repo" -Task "Jawab dalam Bahasa Indonesia. Baca repo ini dan cari bug pada fitur login. Jangan edit dulu, laporkan temuanmu."
```

Untuk Git Bash/Linux/macOS:

```bash
./agent.sh --path "/path/ke/repo-target"
```

Kalau kamu benar-benar ingin menyalin skill ke repo target, gunakan flag eksplisit:

```powershell
.\agent.ps1 -Path "C:\path\to\target-repo" -InstallLocalSkills
```

Biasanya tidak perlu memakai flag ini. Default launcher lebih bersih untuk repo public karena skill tetap tinggal di repo setup ini.

## 5. Saat Masuk CodeWhale

Kalau CodeWhale menanyakan provider atau model:

- Pilih provider: `deepseek`.
- Pilih model: gunakan pilihan default atau recommended dari CodeWhale.
- Kalau ada pilihan auth/API key: pakai `DEEPSEEK_API_KEY` dari file `.env`.

Kalau sudah masuk tampilan chat, kamu bisa ketik:

```text
/provider deepseek
```

Lalu pakai prompt pembuka ini:

```text
Jawab selalu dalam Bahasa Indonesia kecuali untuk nama file, command, error, dan istilah teknis.
Baca repo ini. Mulai dari README.md dan file instruksi di .deepseek/skills jika ada.
Scan struktur folder, deteksi bahasa/framework, jelaskan cara menjalankan project,
dan sebutkan konvensi penting yang harus kamu ikuti sebelum mengedit code.
```

Kalau ingin format laporan yang rapi, gunakan prompt ini:

```text
Buat laporan repo dalam Bahasa Indonesia dengan format:
1. Ringkasan
2. Struktur folder penting
3. Bahasa/framework/tools yang terdeteksi
4. Cara menjalankan project
5. Cara test/build
6. Risiko atau hal yang perlu saya konfirmasi
```

Contoh prompt pertama yang bisa kamu berikan ke agent:

```text
Baca repo ini. Mulai dari README.md dan file instruksi di .deepseek/skills jika ada.
Scan struktur folder, deteksi bahasa/framework, jelaskan cara menjalankan project,
dan sebutkan konvensi penting yang harus kamu ikuti sebelum mengedit code.
```

## 6. Skill Agent

Instruksi project ada di:

```text
.deepseek/skills/project-conventions/SKILL.md
```

Instruksi membaca dokumen ada di:

```text
.deepseek/skills/document-reading/SKILL.md
```

Kalau project ini berkembang, update `project-conventions/SKILL.md` supaya agent makin paham aturan project: struktur folder, style code, cara test, format commit, dan hal lain yang wajib diikuti.

## 7. Membaca PDF, Excel, dan CSV

Taruh dokumen lokal di:

```text
docs-input/
```

Contoh:

```text
docs-input/laporan.xlsx
docs-input/spec.pdf
docs-input/data.csv
```

Install dependency Python jika setup memberi pesan bahwa dependency belum ada:

```powershell
python -m pip install pandas openpyxl pdfplumber
```

Kalau Windows kamu memakai launcher `py`:

```powershell
py -m pip install pandas openpyxl pdfplumber
```

Contoh prompt untuk Excel:

```text
Jawab dalam Bahasa Indonesia.
Gunakan skill document-reading. Baca docs-input/laporan.xlsx.
Inspect semua sheet, kolom, tipe data, sample rows, dan formula jika ada.
Lalu rangkum temuannya.
```

Contoh prompt untuk PDF:

```text
Jawab dalam Bahasa Indonesia.
Gunakan skill document-reading. Baca docs-input/spec.pdf.
Extract text dan tabel per halaman, lalu rangkum poin pentingnya.
Kalau PDF ini hasil scan dan butuh OCR, beri tahu saya.
```

## 8. Menggunakan Setup Ini di Repo Lain

Kalau kamu ingin repo lain punya setup agent yang benar-benar berdiri sendiri, copy file/folder berikut ke repo tersebut:

```text
.deepseek/
docs-input/.gitkeep
.env.example
setup.ps1
setup.sh
```

Tambahkan juga aturan ini ke `.gitignore` repo tersebut:

```gitignore
.env
.env.*
!.env.example

docs-input/*
!docs-input/.gitkeep
```

Setelah itu jalankan setup dari root repo tersebut:

```powershell
.\setup.ps1
```

Untuk penggunaan harian, lebih disarankan pakai `agent.ps1 -Path "C:\path\to\target-repo"` dari repo setup ini supaya repo target tidak dipenuhi file skill tambahan.

## 9. Catatan Keamanan

Jangan commit `.env`.

Jangan commit API key, token, password, credential, cookie, atau file rahasia lain.

File di `docs-input/` tidak ikut ke-commit, kecuali `docs-input/.gitkeep`. Folder ini cocok untuk dokumen lokal seperti PDF, Excel, dan CSV yang mungkin sensitif.

## 10. Troubleshooting

Jika `codewhale` tidak dikenali setelah install, tutup terminal lalu buka terminal baru.

Jika Python dependency belum ada, jalankan:

```powershell
python -m pip install pandas openpyxl pdfplumber
```

Jika PowerShell menolak menjalankan script, jalankan:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

Lalu coba lagi:

```powershell
.\setup.ps1
```

Jika muncul error:

```text
HTTP 402: Insufficient Balance
```

Artinya CodeWhale sudah interaktif, tetapi provider AI menolak request karena saldo/quota API tidak cukup atau credential/provider yang aktif salah. Cek dengan:

```powershell
codewhale auth status
codewhale doctor
```

Lalu pastikan akun DeepSeek punya saldo/quota dan API key benar. Jika perlu set ulang key:

```powershell
codewhale auth set --provider deepseek
```
