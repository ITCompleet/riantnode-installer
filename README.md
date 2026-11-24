# RiantNode installer voor Pterodactyl

Pterodactyl in één keer op een schone server: panel, database, Wings en de FiveM-egg, meteen aan elkaar gekoppeld. Drie vragen, de rest gaat vanzelf.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/ITCompleet/riantnode-installer/main/install.sh)
```

Draai het als root op een **schone** server met Debian 12 of 13, of Ubuntu 22.04 of 24.04. Geen curl? Eerst `apt-get install -y curl`.

## De drie vragen

1. **Wat** wil je installeren: alles op deze server, alleen het panel, of alleen Wings.
2. **Domein** voor het panel. Laat je het leeg, dan draait alles op het IP-adres zonder SSL.
3. **E-mailadres** voor je beheeraccount.

Al het andere krijgt een goede standaard:

| Onderdeel | Standaard |
|---|---|
| SSL | Let's Encrypt, automatisch zodra je een domein opgeeft, verlengt zichzelf |
| Beheerder | gebruikersnaam `beheer` met een sterk gegenereerd wachtwoord |
| Tijdzone | die van de server, anders Europe/Amsterdam |
| Firewall | ufw aan, alleen SSH, panel, Wings en de serverpoorten open |
| Poorten | 25565-25574 (Minecraft), 30120-30129 (FiveM), 40120-40129 (txAdmin) |
| FiveM | de officiële egg uit [pterodactyl/game-eggs](https://github.com/pterodactyl/game-eggs/tree/main/gta/fivem), met txAdmin |

Controleert vooraf of je domein naar de server wijst. Zo niet, dan zegt hij dat (ook als de Cloudflare-proxy aanstaat) en kun je het rechtzetten en opnieuw laten meten.

## Wat er op de server komt

Bij **alles op deze server**:

- Pterodactyl panel, de laatste stabiele 1.x-versie, met PHP 8.2 of 8.3, MariaDB, Redis, nginx en Composer
- de wachtrij (`pteroq`) en de planner (cron)
- Docker en Wings, de laatste stabiele versie
- een locatie, een node met het geheugen en de schijf van de server, en de poorten
- een databasehost, zodat gameservers met één klik een MySQL-database krijgen
- de FiveM-egg in een eigen nest
- de firewall

Na afloop **meet** de installer of alles echt draait: de inlogpagina, de wachtrij, Wings, de databasehost, het certificaat en de firewall. Wat hij niet kan bevestigen, staat niet groen.

Wachtwoorden staan daarna in `/root/riantnode-installer.txt` (alleen leesbaar voor root). Het logboek staat in `/var/log/riantnode-installer.log`.

## Zonder vragen

Geef de antwoorden mee als omgevingsvariabele. Met `RN_JA=1` stelt hij geen enkele vraag, handig voor cloud-init of een eigen script.

```bash
RN_JA=1 RN_DOMEIN=panel.voorbeeld.nl RN_EMAIL=jij@voorbeeld.nl bash install.sh
```

| Variabele | Betekenis | Standaard |
|---|---|---|
| `RN_MODUS` | `alles`, `panel` of `wings` | `alles` |
| `RN_DOMEIN` | domein van panel en node | leeg, alleen IP |
| `RN_EMAIL` | e-mail van de beheerder | verplicht |
| `RN_GEBRUIKER` | gebruikersnaam | `beheer` |
| `RN_WACHTWOORD` | wachtwoord | sterk, gegenereerd |
| `RN_TIJDZONE` | tijdzone | van de server |
| `RN_SSL` | `j`/`n` Let's Encrypt | `j` met domein |
| `RN_FIREWALL` | `j`/`n` ufw | `j` |
| `RN_FIVEM` | `j`/`n` FiveM-egg | `j` |
| `RN_POORTEN` | poortreeksen | zie boven |
| `RN_KOPPEL` | bij `wings`: het commando uit het panel (Configuration, Generate Token) | leeg |

Met een domein vraagt de installer een certificaat aan bij Let's Encrypt. Daarmee ga je akkoord met [hun voorwaarden](https://letsencrypt.org/repository/).

## Eerlijk over de grenzen

- **Alleen voor een schone server.** Staat er al een panel of Wings, dan stopt hij zonder iets aan te raken. Bijwerken of herinstalleren doet deze installer niet.
- **Cloudflare-proxy uit.** Wings en Let's Encrypt werken niet achter de oranje wolk. Zet het record op grijs (DNS only).
- **Achter NAT** (thuis of bij sommige clouds) praat Wings lokaal met het panel, dat lost de installer zelf op. Spelers en de live console hebben wel doorgestuurde poorten nodig op je router.
- **FiveM op arm64** kan niet: FiveM bestaat alleen voor x86_64. Kies je op een arm64-server voor alles, dan slaat hij de egg over.
- **Zonder firewall** is MariaDB van buitenaf bereikbaar, want gameservers in Docker hebben hem nodig. Laat de firewall aan, of zet poort 3306 zelf dicht voor alles behalve `172.18.0.0/16`.
- **E-mail** stelt hij niet in. Doe dat in het panel bij Admin, Settings, Mail.
- **Getest** op Debian 13 (panel v1.15.2, Wings v1.13.5), interactief en zonder vragen. De FiveM-egg is geïmporteerd en gecontroleerd; een draaiende FiveM-server vraagt je eigen sleutel van [portal.cfx.re](https://portal.cfx.re/).

## Goed om te weten

In Pterodactyl 1.x zet `php artisan p:environment:setup --telemetry=false` de telemetrie juist **aan**: door de volgorde van `??` en `? :` in de code telt de tekst `false` als waar. Deze installer geeft daarom `--telemetry=0` mee. Doe je het met de hand, gebruik dan ook `0`.

## Over

Gemaakt door [RiantNode](https://riantnode.com), open source onder de MIT-licentie. Gratis en zonder garantie: na de installatie is de server helemaal van jou.

Pterodactyl is een project van de [Pterodactyl-ontwikkelaars](https://pterodactyl.io) en staat los van RiantNode. De FiveM-egg komt uit [pterodactyl/game-eggs](https://github.com/pterodactyl/game-eggs).

Iets kapot? Open een [issue](https://github.com/ITCompleet/riantnode-installer/issues) met het logboek erbij (haal er eerst wachtwoorden uit).
