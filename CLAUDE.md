# spoofmac

macOS için SpoofDPI yardımcı aracı: tek komutla aç/kapat, halka açık Wi‑Fi (captive portal) modu,
sistem proxy'sini kullanmayan uygulamalar için başlatıcı (Discord), teşhis (`doctor`). Tek dosyalık
zsh betiği. Herkese açık yayınlanmak üzere yazıldı, dikkat çekmesi hedefleniyor.

**Durum (23 Eyl 2026):** v0.1.0 yazıldı, uçtan uca test edildi ve **public** olarak yayında:
https://github.com/aliemrevezir/spoofmac (README'ler ve `install.sh` bu adrese bağlı).

**Makineye özel notlar `CLAUDE.local.md`'de** (git'e girmez): kullanıcının eski kurulumu, geçiş
adımları, proxy'yi test ederken oturumun kopmaması için dikkat edilecekler. Varsa önce onu oku.

## Dosyalar

| Dosya | İçerik |
|---|---|
| `bin/spoofmac` | Tüm araç. Komutlar: install, on/off (resume = on), portal, status, doctor, app, shellenv, logs, uninstall |
| `install.sh` | Komutu `~/.local/bin`'e kopyalar; klondan ya da `curl … \| zsh` ile |
| `extras/cloudflare-doh-failover.mobileconfig` | İsteğe bağlı sistem DoH profili, `AllowFailover` açık |
| `README.md` / `README.tr.md` | İngilizce / Türkçe. **İkisi birlikte güncellenir**, biri diğerinin çevirisi gibi durmalı |

## Kurallar

- Kod yorumları İngilizce. Kullanıcıya giden her mesaj iki dilli: `say "EN" "TR"` / `t "EN" "TR"`.
  Dil `SPOOFMAC_LANG` → `LC_ALL`/`LANG` → `defaults read -g AppleLanguages` sırasıyla seçilir.
- Kişisel veri yok: etiketler `local.spoofmac.*`, kullanıcı adı ya da makineye özel yol kodda geçmez.
- README'de yalnız **ölçülmüş** şeyler iddia edilir. "Test edildiği ortam" bölümü dürüst kalmalı.
- Sözdizimi kontrolü: `zsh -n bin/spoofmac`.

## Ölçülmüş gerçekler (23 Eyl 2026, Türkiye, Starbucks Wi‑Fi + iPhone hotspot, macOS 26.6.2)

- Sistem DNS'i engelli adresleri `195.175.254.2`'ye (ve hotspot'ta `2a01:358:4014:a00::3`'e) çözüyor.
  **UDP 53 dışarıya tamamen kapalı** (1.1.1.1, 8.8.8.8 … zaman aşımı). `1.1.1.1:443` açık.
- `dig` sistem çözücüsünü atlar; DoH profili varken bile yanıltır. Doğru test `dscacheutil -q host -a name <host>`.
- **SNI/DPI:** gerçek IP'ye doğrudan HTTPS → TLS sırasında reset (curl exit 35, Discord'da `-9806`).
- **SpoofDPI 1.5.3 (Homebrew):**
  - `--help` `--dns-mode` için `doh` diyor ama program yalnız `udp | https | system` kabul ediyor.
  - Varsayılan `--https-split-mode sni` bu ağda **çalışmadı**. Çalışanlar: `chunk` 1, `chunk` 5,
    `chunk 1 + --https-disorder`, `random`. `--https-fake-count 1` eklenince her ikisi de bozuldu.
  - Logdaki `"request blocked"`, SpoofDPI'ın kuralı değil: karşı tarafın ECONNRESET'i
    (`internal/server/http/handler_https.go` → `netutil.ErrBlocked`).
  - Bayraklar 0.x sürümünden tamamen farklı (`--listen-addr`, `--dns-mode`, `--no-tui`,
    `--auto-configure-network` …). 0.x'te `--version` yok; betik bu yüzden 1.x şartı koşuyor.
- **Discord:** pencere (Chromium) sistem proxy'sini kullanıyor. **Güncelleyici** (Rust/reqwest,
  `Discord_updater_rCURRENT.log`) kullanmıyor; `HTTPS_PROXY` env'ini ise okuyor.
  `open -a Discord --env HTTPS_PROXY=…` ile güncelleyici geçti. DoH tek başına yetmedi (DNS düzelince
  SNI reset'i). Başlatıcıyla açılan Discord'un **tüm** soketleri proxy'ye gidiyor, DoH gereksiz.
  Sesli sohbet (UDP, doğrudan IP) **DoH'suz test edilmedi**.
- **osacompile applet tuzakları:** (1) `CFBundleIdentifier` yok → Raycast listelemiyor;
  (2) `Assets.car` + `CFBundleIconName`, `applet.icns`'in önüne geçiyor; (3) var olan bir `.app`'in
  üzerine `mv` yapınca yeni paket **içine** yuvalanıyor ve imza bozuluyor ("unsealed contents present
  in the bundle root"). Üçü de `cmd_app` içinde çözülü; her değişiklikten sonra `codesign --force --deep -s -`.
- **`AllowFailover`** (`com.apple.dnsSettings.managed`, macOS 26+) Apple'ın device-management
  şemasında var; profil hatasız kuruldu ve DoH çalıştı. **Giriş öncesi captive portal'da test edilmedi.**
- Raycast'in yeni sürümünde ayar yeri: Settings → sol menü **Applications** → Alias / Hotkey sütunları.

## Test edildi / edilmedi

- ✓ `install → status → portal → on → off → uninstall`, `app`, `doctor`, `help` (TR/EN) — Starbucks
  Wi‑Fi'ında, yan portta (18080).
- ✓ Portal akışı gerçek Starbucks giriş sayfasında **prototiple** (`wifi-portal`, aynı mantık).
- ✓ `install.sh` hem dosyadan hem yayındaki repodan `curl … | zsh` ile (geçici `PREFIX`).
- ✗ spoofmac'in kendisiyle gerçek giriş sayfası, Intel Mac, macOS < 26, Türkiye dışı ağlar,
  Discord sesli sohbet.

## Test yöntemi (önemli)

- Kullanıcının kendi kurulumunu bozmamak için **yan port + geçici config** kullan:
  ```bash
  SP=$(mktemp -d); mkdir -p $SP/cfg/spoofmac $SP/apps
  printf 'LISTEN_PORT="18080"\n' > $SP/cfg/spoofmac/config
  XDG_CONFIG_HOME=$SP/cfg bin/spoofmac install   # … testler …
  XDG_CONFIG_HOME=$SP/cfg bin/spoofmac uninstall
  SPOOFMAC_APPS_DIR=$SP/apps bin/spoofmac app Discord   # başlatıcıyı /Applications dışına üretir
  ```
  `on` sistem proxy'sini test portuna çevirir. Testten sonra makinenin önceki proxy ayarını geri yükle.
- Oturumun kendisi `HTTPS_PROXY` ile SpoofDPI'dan geçiyorsa, o proxy'yi durduran ve geri açan adımlar
  **tek Bash komutunda** olmalı; araya API çağrısı girerse oturum kopar.

## Yol haritası

1. Kullanıcının makinesini eski kurulumdan spoofmac'e geçir (`CLAUDE.local.md`).
2. Giriş sayfasını otomatik algılama: ağ değişince (SSID/IP) captive ise `portal`, giriş bitince `on`.
3. Homebrew tap (`brew install aliemrevezir/tap/spoofmac`).
4. `spoofmac app --remove <App>`; başlatıcı açıkken hedef uygulama env'siz çalışıyorsa uyar.
5. README için ekran görüntüsü / GIF (doctor çıktısı, Discord öncesi/sonrası).
6. CI: macOS runner'da `zsh -n` + `spoofmac help`.
7. Sesli sohbeti (UDP) test et; gerekirse `--app-mode tun` / UDP ayarlarını araştır.
8. İlk sürüm etiketi (`v0.1.0`) + GitHub release notu.
