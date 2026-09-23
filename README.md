# spoofmac

**SpoofDPI on macOS, minus the pain.** One command to turn it on and off, a public Wi‑Fi mode that doesn't
fight login pages, a fix for apps that ignore the system proxy (hello, Discord stuck on
*"Checking for updates…"*), and a doctor that tells you what's actually being blocked.

🇹🇷 [Türkçe README](README.tr.md)

```text
$ spoofmac doctor discord.com
spoofmac doctor · discord.com

Internet               online
DoH (1.1.1.1)          162.159.137.232 162.159.138.232 …
System DNS             ✗ 195.175.254.2 — differs from DoH: DNS is tampered with
Plain DNS (UDP 53)     blocked
Direct HTTPS           ✗ reset during TLS — SNI/DPI filtering
Via SpoofDPI           ✓ 200

Verdict: SNI/DPI filtering + DNS tampering. SpoofDPI is needed, and apps that ignore
the system proxy need a launcher: spoofmac app <App>
```

## Why

[SpoofDPI](https://github.com/xvzc/SpoofDPI) gets you past DPI‑based blocking by splitting the TLS
handshake. It works. Living with it on a Mac is the annoying part:

- **Public Wi‑Fi breaks.** Café, airport and hotel networks show a login page before letting you out.
  SpoofDPI looks up names through an outside resolver, and that resolver is unreachable until you log in.
  Nothing loads, not even the login page.
- **Some apps ignore the system proxy.** Discord's window uses it; Discord's *updater* doesn't. The
  updater hits the blocked DNS answer or gets its TLS reset, and Discord never gets past the splash screen.
- **If SpoofDPI stops, the internet stops.** The system proxy keeps pointing at a port nobody's
  listening on.
- **"Is it DNS? Is it DPI? Is it me?"** is guesswork without the right tests.

spoofmac is a single zsh script that handles all of that.

## Install

```bash
brew install spoofdpi
git clone https://github.com/aliemrevezir/spoofmac.git && cd spoofmac && ./install.sh
spoofmac install
```

`install.sh` copies the `spoofmac` command to `~/.local/bin`. It also works piped:
`curl -fsSL https://raw.githubusercontent.com/aliemrevezir/spoofmac/main/install.sh | zsh`.
`spoofmac install` sets up a LaunchAgent (SpoofDPI starts at login and restarts if it crashes), then
points the system proxy at it.

Requires macOS with an admin account (to change network settings) and SpoofDPI **1.x** from Homebrew.

## Usage

| Command | What it does |
|---|---|
| `spoofmac on` / `off` | Turn SpoofDPI and the system proxy on or off. `off` stays off across reboots. |
| `spoofmac portal ["Wi‑Fi name"]` | Public Wi‑Fi: pause SpoofDPI, optionally join the network, open the login page. |
| `spoofmac status` | What's running, where the proxy points, whether you're online, and a live test. |
| `spoofmac doctor [host]` | What blocks `host` on this network: DNS, SNI/DPI, or nothing. |
| `spoofmac app <App>` | Create `<App> SpoofDPI.app`, which starts the app with proxy variables set. |
| `spoofmac shellenv` | Proxy variables for your terminal: `eval "$(spoofmac shellenv)"` |
| `spoofmac logs` | Follow SpoofDPI's log. |
| `spoofmac uninstall` | Stop and remove the background service. |

Messages come out in Turkish when your system language is Turkish. Force a language with
`SPOOFMAC_LANG=en` or `SPOOFMAC_LANG=tr`.

**Internet gone?** `spoofmac off`. If the command itself is gone too:

```bash
networksetup -setwebproxystate Wi-Fi off && networksetup -setsecurewebproxystate Wi-Fi off
```

## Public Wi‑Fi (Starbucks, airports, hotels)

```bash
spoofmac portal "STARBUCKS FREE WIFI"   # or just: spoofmac portal (if you're already connected)
# … log in on the page that opens …
spoofmac on
```

`on` won't switch SpoofDPI back on while the login page is still in the way, so you can't lock
yourself out by running it too early. If SpoofDPI can't get out on this particular network, `on`
switches it off again so you at least keep a normal connection.

## Discord stuck on "Checking for updates…" / "Update failed"

This is what actually happens, measured on a Mac with SpoofDPI running:

1. The Discord **window** (Chromium) goes through the system proxy, so SpoofDPI handles it.
2. The Discord **updater** is a separate native component. It **doesn't use the macOS system proxy**.
   It resolves `updates.discord.com` with the system DNS and connects directly.
3. With a tampered DNS it gets a block‑page IP and times out. With a clean DNS (for example a DoH
   profile) it reaches the real server, and then DPI resets the TLS handshake
   (`-9806 connection closed via error` in `~/Library/Application Support/discord/logs/Discord_updater_rCURRENT.log`).
   So DoH alone doesn't fix Discord either.
4. The updater does honour the `HTTPS_PROXY` environment variable. Started with it, the updater goes
   through SpoofDPI and passes: *"Already up to date… Update to latest complete."*

The fix:

```bash
spoofmac app Discord      # creates /Applications/Discord SpoofDPI.app
```

Quit Discord (⌘Q) and open **Discord SpoofDPI** from now on. It has Discord's icon, so put it in
the Dock in place of the original. Opening the original Discord brings the problem back.

**Raycast:** Settings → Applications → set the alias `discord` on *Discord SpoofDPI*, and untick the
original *Discord* so you can't pick it by accident.

The same trick works for any app with a native HTTP client that ignores the system proxy but reads
`HTTPS_PROXY`: `spoofmac app "Some App"`.

## Configuration

`~/.config/spoofmac/config` is created on first install. Edit it, then run `spoofmac install` again.

| Key | Default | Notes |
|---|---|---|
| `LISTEN_PORT` | `8080` | Local proxy port. |
| `DOH_URL` | `https://1.1.1.1/dns-query` | How SpoofDPI resolves names. It's an IP, so no bootstrap lookup is needed. |
| `SPLIT_MODE` | `chunk` | `chunk`, `random`, `sni` or `none`. |
| `CHUNK_SIZE` | `5` | Try `1` if 5 stops working. |
| `EXTRA_ARGS` | `()` | Any other SpoofDPI flags, e.g. `(--https-disorder)`. |
| `TEST_URL` | Discord's gateway | What `status` tests and `doctor` checks by default. |

**Why `chunk` 5 and not SpoofDPI's default?** On the networks tested, SpoofDPI 1.5.3's default
(`sni`) was reset by the DPI. `chunk` with 1 or 5 bytes and `random` got through; adding
`--https-fake-count` broke it again. If yours behaves differently, `doctor` will show it.

## Optional: system‑wide DoH

spoofmac doesn't need it, because SpoofDPI resolves names on its own. A DoH profile helps **other**
apps that don't use the proxy. The old catch was public Wi‑Fi: with DoH on, the login page can't
load. `extras/cloudflare-doh-failover.mobileconfig` sets `AllowFailover` (macOS 26+): when the DoH
server is unreachable, macOS falls back to the network's DNS.

```bash
open extras/cloudflare-doh-failover.mobileconfig
```

Then approve it in System Settings → General → Device Management.

## How it works

```text
 Browser, Discord window ──(system proxy)──┐
 Discord updater ──(HTTPS_PROXY, via launcher)─┤
                                               ▼
                               SpoofDPI 127.0.0.1:8080
                               ├─ resolves names over DoH (1.1.1.1)
                               └─ splits the TLS ClientHello so DPI can't read the SNI
                                               ▼
                                            Internet
```

- A LaunchAgent (`local.spoofmac.spoofdpi`) runs SpoofDPI with `KeepAlive`. `off` uses
  `launchctl disable`, so it stays off after a reboot.
- The proxy is set on **every** enabled network service, so moving between Wi‑Fi, Ethernet and an
  iPhone keeps working. `off` only removes proxies that point at SpoofDPI; a corporate proxy is left
  alone.
- Captive portals are detected with Apple's own probe (`captive.apple.com`), always asked directly
  and never through the proxy.

## Tested on

- macOS 26.6 on Apple Silicon, SpoofDPI 1.5.3 (Homebrew), in Turkey.
- `doctor`'s sample output above is real, from a café Wi‑Fi in Turkey. The full
  `install → portal → on → off → uninstall` cycle and `spoofmac app` were run on the same network.
- The Discord launcher fix was first verified with an older SpoofDPI build: the updater went from
  "Update failed" to "Update to latest complete". With 1.5.3 and spoofmac's defaults, the updater's
  endpoint (`updates.discord.com`) returns 200 through SpoofDPI.
- The public Wi‑Fi flow was used on a real Starbucks login page, with the prototype of this script.

Other countries, ISPs and macOS versions are untested. Issues and PRs with `spoofmac doctor` output
are very welcome.

## Disclaimer

spoofmac only configures your own Mac and wraps [SpoofDPI](https://github.com/xvzc/SpoofDPI), which
does the actual work. It isn't affiliated with SpoofDPI or Discord. You're responsible for how you use
it and for following the laws where you are.

## License

[MIT](LICENSE)
