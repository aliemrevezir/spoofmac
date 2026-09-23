# spoofmac

**macOS'ta SpoofDPI, derdi olmadan.** Tek komutla aç/kapat, giriş sayfalı Wi‑Fi'larla kavga etmeyen
bir mod, sistem proxy'sini kullanmayan uygulamalar için çözüm (evet, *"Checking for updates…"*
ekranında takılan Discord) ve neyin engellendiğini söyleyen bir teşhis komutu.

🇬🇧 [English README](README.md)

```text
$ spoofmac doctor discord.com
spoofmac doctor · discord.com

İnternet               online
DoH (1.1.1.1)          162.159.137.232 162.159.138.232 …
Sistem DNS'i           ✗ 195.175.254.2 — DoH'tan farklı: DNS'e müdahale var
Düz DNS (UDP 53)       kapalı
Doğrudan HTTPS         ✗ TLS sırasında koparıldı — SNI/DPI filtresi
SpoofDPI üstünden      ✓ 200

Sonuç: SNI/DPI filtresi + DNS müdahalesi. SpoofDPI şart; sistem proxy'sini kullanmayan
uygulamalar için başlatıcı gerekir: spoofmac app <Uygulama>
```

## Neden

[SpoofDPI](https://github.com/xvzc/SpoofDPI), TLS el sıkışmasını parçalayarak DPI tabanlı engelleri
aşıyor ve işini yapıyor. Mac'te onunla yaşamak ise can sıkıcı:

- **Kafe, havalimanı, otel Wi‑Fi'ları bozuluyor.** Bu ağlar dışarı çıkmadan önce bir giriş sayfası
  gösterir. SpoofDPI adresleri dışarıdaki bir çözücüye sorar; o çözücüye giriş yapmadan ulaşılamaz.
  Hiçbir şey açılmaz, giriş sayfası bile.
- **Bazı uygulamalar sistem proxy'sini kullanmıyor.** Discord'un penceresi kullanıyor, *güncelleyicisi*
  kullanmıyor. Güncelleyici ya engelli DNS yanıtına takılıyor ya da TLS'i koparılıyor. Discord açılış
  ekranını geçemiyor.
- **SpoofDPI durursa internet de durur.** Sistem proxy'si kimsenin dinlemediği bir portu göstermeye
  devam eder.
- **"DNS mi, DPI mı, ben mi?"** sorusu doğru testler olmadan tahmin işi.

spoofmac, bunların hepsini halleden tek bir zsh betiği.

## Kurulum

```bash
brew install spoofdpi
git clone https://github.com/aliemrevezir/spoofmac.git && cd spoofmac && ./install.sh
spoofmac install
```

`install.sh`, `spoofmac` komutunu `~/.local/bin`'e kopyalar. Tek satırla da olur:
`curl -fsSL https://raw.githubusercontent.com/aliemrevezir/spoofmac/main/install.sh | zsh`.
`spoofmac install` bir LaunchAgent kurar (SpoofDPI oturum açılınca başlar, çökerse yeniden başlar) ve
sistem proxy'sini ona yönlendirir.

Gerekenler: macOS, yönetici hesabı (ağ ayarlarını değiştirmek için) ve Homebrew'dan SpoofDPI **1.x**.

## Kullanım

| Komut | Ne yapar |
|---|---|
| `spoofmac on` / `off` | SpoofDPI'ı ve sistem proxy'sini açar/kapatır. `off` yeniden başlatmadan sonra da kapalı kalır. |
| `spoofmac portal ["Wi‑Fi adı"]` | Halka açık Wi‑Fi: SpoofDPI'ı durdurur, istersen ağa bağlanır, giriş sayfasını açar. |
| `spoofmac status` | Ne çalışıyor, proxy nereyi gösteriyor, internet var mı, canlı test. |
| `spoofmac doctor [adres]` | Bu ağda `adres`'i ne engelliyor: DNS, SNI/DPI ya da hiçbir şey. |
| `spoofmac app <Uygulama>` | Uygulamayı proxy değişkenleriyle başlatan `<Uygulama> SpoofDPI.app`'i oluşturur. |
| `spoofmac shellenv` | Terminal için proxy değişkenleri: `eval "$(spoofmac shellenv)"` |
| `spoofmac logs` | SpoofDPI logunu izler. |
| `spoofmac uninstall` | Arka plan servisini durdurur ve kaldırır. |

Sistem dilin Türkçeyse mesajlar Türkçe gelir. Dili zorlamak için `SPOOFMAC_LANG=tr` ya da
`SPOOFMAC_LANG=en`.

**İnternet gitti mi?** `spoofmac off`. Komut da çalışmıyorsa:

```bash
networksetup -setwebproxystate Wi-Fi off && networksetup -setsecurewebproxystate Wi-Fi off
```

## Halka açık Wi‑Fi (Starbucks, havalimanı, otel)

```bash
spoofmac portal "STARBUCKS FREE WIFI"   # ya da ağa zaten bağlıysan: spoofmac portal
# … açılan sayfada giriş yap …
spoofmac on
```

Giriş sayfası hâlâ aradayken `on` SpoofDPI'ı açmaz; erken çalıştırıp kendini dışarıda bırakamazsın.
SpoofDPI o ağda dışarı çıkamıyorsa `on` onu geri kapatır, en azından normal internetin kalır.

## "Checking for updates…" / "Update failed" ekranında takılan Discord

SpoofDPI çalışan bir Mac'te ölçülen tablo şu:

1. Discord **penceresi** (Chromium) sistem proxy'sini kullanıyor, yani SpoofDPI'dan geçiyor.
2. Discord **güncelleyicisi** ayrı, yerel bir bileşen ve **macOS sistem proxy'sini kullanmıyor**.
   `updates.discord.com`'u sistem DNS'iyle çözüp doğrudan bağlanıyor.
3. DNS'e müdahale varsa engel sayfasının IP'sini alıp zaman aşımına düşüyor. DNS temizse (örneğin bir
   DoH profiliyle) gerçek sunucuya ulaşıyor, bu sefer de DPI TLS el sıkışmasını koparıyor
   (`~/Library/Application Support/discord/logs/Discord_updater_rCURRENT.log` içinde
   `-9806 connection closed via error`). Yani DoH tek başına Discord'u da düzeltmiyor.
4. Güncelleyici `HTTPS_PROXY` ortam değişkenini ise dikkate alıyor. Bu değişkenle başlatılınca
   SpoofDPI'dan geçiyor ve sorunsuz tamamlanıyor: *"Already up to date… Update to latest complete."*

Çözüm:

```bash
spoofmac app Discord      # /Applications/Discord SpoofDPI.app oluşturur
```

Discord'u kapat (⌘Q) ve bundan sonra **Discord SpoofDPI**'dan aç. Discord'un ikonunu taşıyor, Dock'ta
orijinalin yerine koy. Orijinal Discord'dan açarsan sorun geri gelir.

**Raycast:** Ayarlar → Applications → *Discord SpoofDPI* satırına `discord` takma adını ver, yanlışlıkla
seçmemek için orijinal *Discord*'un işaretini kaldır.

Aynı yöntem, sistem proxy'sini yok sayıp `HTTPS_PROXY`'yi okuyan kendi HTTP istemcisi olan her
uygulamada işe yarar: `spoofmac app "Bir Uygulama"`.

## Ayarlar

`~/.config/spoofmac/config` ilk kurulumda oluşur. Düzenle, sonra `spoofmac install`'ı tekrar çalıştır.

| Anahtar | Varsayılan | Not |
|---|---|---|
| `LISTEN_PORT` | `8080` | Yerel proxy portu. |
| `DOH_URL` | `https://1.1.1.1/dns-query` | SpoofDPI'ın adres çözme yolu. IP olduğu için önce başka bir sorgu gerekmez. |
| `SPLIT_MODE` | `chunk` | `chunk`, `random`, `sni` ya da `none`. |
| `CHUNK_SIZE` | `5` | 5 çalışmazsa `1` dene. |
| `EXTRA_ARGS` | `()` | Diğer SpoofDPI bayrakları, ör. `(--https-disorder)`. |
| `TEST_URL` | Discord gateway | `status`'un test ettiği, `doctor`'ın varsayılan olarak baktığı adres. |

**Neden SpoofDPI'ın varsayılanı değil de `chunk` 5?** Test edilen ağlarda SpoofDPI 1.5.3'ün varsayılanı
(`sni`) DPI tarafından koparıldı. `chunk` 1 ya da 5 bayt ve `random` geçti; `--https-fake-count` eklemek
yeniden bozdu. Senin ağın farklı davranıyorsa `doctor` gösterir.

## İsteğe bağlı: sistem genelinde DoH

spoofmac'in buna ihtiyacı yok, SpoofDPI adresleri kendisi çözüyor. DoH profili proxy kullanmayan
**diğer** uygulamalar için işe yarar. Eskiden sorun halka açık Wi‑Fi'lardı: DoH açıkken giriş sayfası
açılmıyordu. `extras/cloudflare-doh-failover.mobileconfig` içinde `AllowFailover` (macOS 26+) var:
DoH sunucusuna ulaşılamazsa macOS ağın kendi DNS'ine düşer.

```bash
open extras/cloudflare-doh-failover.mobileconfig
```

Sonra Sistem Ayarları → Genel → Aygıt Yönetimi'nden onayla.

## Nasıl çalışıyor

```text
 Tarayıcı, Discord penceresi ──(sistem proxy'si)──┐
 Discord güncelleyicisi ──(HTTPS_PROXY, başlatıcı)─┤
                                                   ▼
                                   SpoofDPI 127.0.0.1:8080
                                   ├─ adresleri DoH ile çözer (1.1.1.1)
                                   └─ DPI SNI'yi okuyamasın diye TLS ClientHello'yu parçalar
                                                   ▼
                                                İnternet
```

- SpoofDPI'ı `KeepAlive` ile bir LaunchAgent (`local.spoofmac.spoofdpi`) çalıştırır. `off`,
  `launchctl disable` kullandığı için yeniden başlatmadan sonra da kapalı kalır.
- Proxy etkin **tüm** ağ servislerine yazılır; Wi‑Fi, Ethernet ve iPhone arasında geçişte bozulmaz.
  `off` yalnız SpoofDPI'ı gösteren proxy'leri kapatır; şirket proxy'sine dokunmaz.
- Giriş sayfası, Apple'ın kendi yoklamasıyla (`captive.apple.com`) tespit edilir. Bu yoklama her zaman
  doğrudan yapılır, proxy'den geçmez.

## Test edildiği ortam

- Apple Silicon üzerinde macOS 26.6, SpoofDPI 1.5.3 (Homebrew), Türkiye.
- Yukarıdaki `doctor` çıktısı gerçek; Türkiye'de bir kafe Wi‑Fi'ından alındı. Tam
  `install → portal → on → off → uninstall` döngüsü ve `spoofmac app` aynı ağda çalıştırıldı.
- Discord başlatıcı çözümü önce SpoofDPI'ın eski bir sürümüyle doğrulandı: güncelleyici
  "Update failed"dan "Update to latest complete"e geçti. 1.5.3 ve spoofmac varsayılanlarıyla
  güncelleyicinin adresi (`updates.discord.com`) SpoofDPI üstünden 200 dönüyor.
- Halka açık Wi‑Fi akışı gerçek bir Starbucks giriş sayfasında, bu betiğin ilk sürümüyle kullanıldı.

Başka ülkeler, operatörler ve macOS sürümleri test edilmedi. `spoofmac doctor` çıktısıyla gelen
issue ve PR'lar çok makbule geçer.

## Sorumluluk

spoofmac yalnızca kendi Mac'ini yapılandırır; asıl işi yapan [SpoofDPI](https://github.com/xvzc/SpoofDPI).
SpoofDPI ya da Discord ile bir bağı yoktur. Nasıl kullandığından ve bulunduğun yerin yasalarına
uymaktan sen sorumlusun.

## Lisans

[MIT](LICENSE)
