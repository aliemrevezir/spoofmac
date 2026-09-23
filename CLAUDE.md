# spoofmac

macOS'ta SpoofDPI ile Discord'a bağlanmak için tek dosyalık zsh aracı. Yanında giriş sayfalı Wi‑Fi
(Starbucks vb.) modu. Public: https://github.com/aliemrevezir/spoofmac

**Makineye özel notlar `CLAUDE.local.md`'de** (git'e girmez): kullanıcının eski kurulumu, geçiş
adımları, proxy'yi test ederken oturumun kopmaması için dikkat edilecekler. Varsa önce onu oku.

## Kapsam — kullanıcının kararı (23 Eyl 2026)

v0.1.0 fazla şey anlatıyordu; kullanıcı **sadeleştirmek** istedi. Ana hikâye: *SpoofDPI'ı kur →
spoofmac ile Discord'u aç.* Yanında giriş sayfalı Wi‑Fi modu. `doctor` ve `logs` var ama README'de
**en sonda** geçer. README kısa kalır: SpoofDPI'ı kur (linkli) → spoofmac'i kur → Discord'u aç →
halka açık Wi‑Fi → sorun olursa. Raycast/Dock ipuçları, DoH profili, ayar tablosu, mimari anlatımı
**bilinçli olarak çıkarıldı**, geri ekleme. Yeni özellik önerirken önce bu kapsama uyuyor mu diye sor.

Komutlar (v0.2.0): `install`, `discord`, `portal [WIFI]`, `on`, `off`, `doctor [HOST]`, `logs`,
`uninstall`. Çıkarılanlar: `status` (bilgisi `doctor`'un başında), genel `app <Uygulama>`, `shellenv`,
`extras/` DoH profili. Ayar dosyası (`~/.config/spoofmac/config`) hâlâ okunur ama belgelenmez;
yalnız `doctor` SpoofDPI geçemezse `CHUNK_SIZE`/`SPLIT_MODE` önerir.

## Dosyalar

| Dosya | İçerik |
|---|---|
| `bin/spoofmac` | Tüm araç |
| `install.sh` | Komutu `~/.local/bin`'e kopyalar; klondan ya da `curl … \| zsh` ile |
| `README.md` / `README.tr.md` | İngilizce / Türkçe, **ikisi birlikte güncellenir**, kısa kalır |

## Kurallar

- Kod yorumları İngilizce. Kullanıcıya giden her mesaj iki dilli: `say "EN" "TR"` / `t "EN" "TR"`.
  Dil `SPOOFMAC_LANG` → `LC_ALL`/`LANG` → `defaults read -g AppleLanguages` sırasıyla seçilir.
- Kişisel veri yok: etiketler `local.spoofmac.*`, kullanıcı adı ya da makineye özel yol kodda geçmez.
- README'de yalnız **ölçülmüş** şeyler iddia edilir.
- Sözdizimi kontrolü: `zsh -n bin/spoofmac`.

## Ölçülmüş gerçekler (23 Eyl 2026, Türkiye, Starbucks Wi‑Fi + iPhone hotspot, macOS 26.6.2)

- Sistem DNS'i engelli adresleri `195.175.254.2`'ye (ve hotspot'ta `2a01:358:4014:a00::3`'e) çözüyor.
  **UDP 53 dışarıya tamamen kapalı** (1.1.1.1, 8.8.8.8 … zaman aşımı). `1.1.1.1:443` açık.
- `dig` sistem çözücüsünü atlar; doğru test `dscacheutil -q host -a name <host>`.
- **SNI/DPI:** gerçek IP'ye doğrudan HTTPS → TLS sırasında reset (curl exit 35, Discord'da `-9806`).
- **SpoofDPI 1.5.3 (Homebrew):**
  - `--help` `--dns-mode` için `doh` diyor ama program yalnız `udp | https | system` kabul ediyor.
  - Varsayılan `--https-split-mode sni` bu ağda **çalışmadı**. Çalışanlar: `chunk` 1, `chunk` 5,
    `chunk 1 + --https-disorder`, `random`. `--https-fake-count 1` eklenince bozuldu.
  - Logdaki `"request blocked"`, SpoofDPI'ın kuralı değil: karşı tarafın ECONNRESET'i
    (`internal/server/http/handler_https.go` → `netutil.ErrBlocked`).
  - Bayraklar 0.x sürümünden tamamen farklı; 0.x'te `--version` yok, betik 1.x şartı koşuyor.
- **Discord:** pencere (Chromium) sistem proxy'sini kullanıyor. **Güncelleyici** (Rust/reqwest,
  `Discord_updater_rCURRENT.log`) kullanmıyor; `HTTPS_PROXY` env'ini ise okuyor. DoH tek başına
  yetmedi (DNS düzelince SNI reset'i). Başlatıcıyla açılan Discord'un **tüm** soketleri proxy'ye gidiyor.
  Açık bir Discord eski env'iyle devam eder → `spoofmac discord` önce kapatıp yeniden açar.
  Sesli sohbet (UDP, doğrudan IP) **test edilmedi**.
- **osacompile applet tuzakları:** (1) `CFBundleIdentifier` yok → Spotlight/Raycast listelemiyor;
  (2) `Assets.car` + `CFBundleIconName`, `applet.icns`'in önüne geçiyor; (3) var olan bir `.app`'in
  üzerine `mv` yapınca yeni paket **içine** yuvalanıyor ve imza bozuluyor. Üçü de `cmd_discord`'da
  çözülü. Başlatıcı bizim bundle id'mizi (`local.spoofmac.discord`) taşıyorsa yeniden kullanılır,
  taşımıyorsa eskisi Çöp Sepeti'ne gider.

## Test edildi / edilmedi

- ✓ v0.2.0: `install → doctor → discord (yeniden kullanım dahil) → portal → on → off → uninstall`,
  `help` (TR/EN) — Starbucks Wi‑Fi'ında, yan portta (18080).
- ✓ Portal akışı gerçek Starbucks giriş sayfasında **prototiple** (`wifi-portal`, aynı mantık).
- ✓ `install.sh` yayındaki repodan `curl … | zsh` ile.
- ✗ spoofmac'in kendisiyle gerçek giriş sayfası, `spoofmac discord`'un Discord'u kapatıp açması
  (testte `SPOOFMAC_NO_OPEN` ile atlandı), Intel Mac, macOS < 26, Türkiye dışı ağlar, sesli sohbet.

## Test yöntemi (önemli)

- Kullanıcının kendi kurulumunu bozmamak için **yan port + geçici config** kullan:
  ```bash
  SP=$(mktemp -d); mkdir -p $SP/cfg/spoofmac $SP/apps
  printf 'LISTEN_PORT="18080"\n' > $SP/cfg/spoofmac/config
  XDG_CONFIG_HOME=$SP/cfg bin/spoofmac install   # … testler …
  XDG_CONFIG_HOME=$SP/cfg SPOOFMAC_NO_OPEN=1 SPOOFMAC_APPS_DIR=$SP/apps bin/spoofmac discord
  XDG_CONFIG_HOME=$SP/cfg bin/spoofmac uninstall
  ```
  `SPOOFMAC_NO_OPEN` başlatıcıyı üretir ama Discord'u kapatıp açmaz; `SPOOFMAC_APPS_DIR` onu
  `/Applications` dışına koyar. `on` sistem proxy'sini test portuna çevirir; testten sonra makinenin
  önceki proxy ayarını geri yükle.
- Oturumun kendisi `HTTPS_PROXY` ile SpoofDPI'dan geçiyorsa, o proxy'yi durduran ve geri açan adımlar
  **tek Bash komutunda** olmalı; araya API çağrısı girerse oturum kopar.

## Yol haritası (kapsamı büyütmeden)

1. Kullanıcının makinesini eski kurulumdan spoofmac'e geçir (`CLAUDE.local.md`).
2. `spoofmac discord`'un kapat-aç adımını ve portal akışını gerçek ortamda dene.
3. Sürüm etiketi (`v0.2.0`) + kısa GitHub release notu.
4. İstenirse: Homebrew tap, README'ye tek bir ekran görüntüsü.
