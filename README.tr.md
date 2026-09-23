# spoofmac

Engelli olduğu yerde Discord'u macOS'ta [SpoofDPI](https://github.com/xvzc/SpoofDPI) ile kullan.
Giriş sayfalı Wi‑Fi'larda da (Starbucks, havalimanı, otel) çalışır.

🇬🇧 [English](README.md)

## 1. SpoofDPI'ı kur

spoofmac, **[SpoofDPI](https://github.com/xvzc/SpoofDPI)** üzerinde çalışır. Önce onu
[Homebrew](https://brew.sh) ile kur:

```bash
brew install spoofdpi
```

## 2. spoofmac'i kur

```bash
curl -fsSL https://raw.githubusercontent.com/aliemrevezir/spoofmac/main/install.sh | zsh
spoofmac install
```

`spoofmac install`, SpoofDPI'ı arka planda (ve her oturum açılışında) başlatır ve Mac'inin trafiğini
ondan geçirir.

## 3. Discord'u aç

```bash
spoofmac discord
```

Discord, SpoofDPI üzerinden açılır. Bundan sonra Discord yerine Uygulamalar'daki **Discord SpoofDPI**'ı
aç. Normal Discord yine *"Checking for updates…"* ekranında takılır, çünkü güncelleyicisi macOS proxy
ayarlarını dikkate almıyor. Discord SpoofDPI, proxy'yi ona doğrudan verir.

## Giriş sayfalı Wi‑Fi

SpoofDPI açıkken Wi‑Fi giriş sayfaları açılmaz. Giriş için durdur:

```bash
spoofmac portal    # SpoofDPI durur, giriş sayfası açılır
                   # … giriş yap …
spoofmac on        # SpoofDPI geri açılır
```

## Bir sorun olursa

```bash
spoofmac doctor    # burada ne engelli, SpoofDPI geçiyor mu?
spoofmac logs      # SpoofDPI logu
spoofmac off       # internet yok mu? SpoofDPI'ı kapat
spoofmac uninstall # her şeyi kaldır
```

---

macOS 26.6 (Apple Silicon) ve SpoofDPI 1.5.3 ile Türkiye'de test edildi. SpoofDPI ya da Discord ile bir
bağı yoktur. [MIT Lisansı](LICENSE).
