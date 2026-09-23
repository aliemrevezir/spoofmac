# spoofmac

Use Discord on macOS where it's blocked, with [SpoofDPI](https://github.com/xvzc/SpoofDPI).
Public Wi‑Fi with a login page (Starbucks, airports, hotels) works too.

🇹🇷 [Türkçe](README.tr.md)

## 1. Install SpoofDPI

spoofmac runs on top of **[SpoofDPI](https://github.com/xvzc/SpoofDPI)**. Install it first with
[Homebrew](https://brew.sh):

```bash
brew install spoofdpi
```

## 2. Install spoofmac

```bash
curl -fsSL https://raw.githubusercontent.com/aliemrevezir/spoofmac/main/install.sh | zsh
spoofmac install
```

`spoofmac install` starts SpoofDPI in the background (and at every login) and sends your Mac's
traffic through it.

## 3. Open Discord

```bash
spoofmac discord
```

Discord opens through SpoofDPI. From now on, open **Discord SpoofDPI** from Applications instead of
Discord. The normal Discord app gets stuck on *"Checking for updates…"* again, because its updater
ignores the macOS proxy settings. Discord SpoofDPI passes the proxy to it directly.

## Public Wi‑Fi

Wi‑Fi login pages don't load while SpoofDPI is on. Pause it for the login:

```bash
spoofmac portal    # SpoofDPI pauses, the login page opens
                   # … log in …
spoofmac on        # SpoofDPI is back
```

## If something's wrong

```bash
spoofmac doctor    # what's blocked here, and does SpoofDPI get through?
spoofmac logs      # SpoofDPI's log
spoofmac off       # no internet? turn SpoofDPI off
spoofmac uninstall # remove everything
```

---

Tested on macOS 26.6 (Apple Silicon) with SpoofDPI 1.5.3, in Turkey. Not affiliated with SpoofDPI or
Discord. [MIT License](LICENSE).
