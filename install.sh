#!/usr/bin/env bash
# ---------------------------------------------------------------------------
#  RiantNode installer voor Pterodactyl
#  Panel, database, Wings en de FiveM-egg in een keer, op een schone server.
#
#  Gebruik:   bash <(curl -fsSL https://raw.githubusercontent.com/ITCompleet/riantnode-installer/main/install.sh)
#  Hulp:      bash install.sh --help
#
#  Open source onder de MIT-licentie. Pterodactyl zelf is een project van de
#  Pterodactyl-ontwikkelaars (pterodactyl.io), niet van RiantNode.
# ---------------------------------------------------------------------------
set -Eeuo pipefail

VERSIE="1.0.0"
LOG=/var/log/riantnode-installer.log
GEGEVENS=/root/riantnode-installer.txt
PANEEL=/var/www/pterodactyl
WERKMAP=/var/lib/riantnode-installer
EGG_URL="https://raw.githubusercontent.com/pterodactyl/game-eggs/main/gta/fivem/egg-five-m.json"
STD_POORTEN="25565-25574 30120-30129 40120-40129"
TTY=/dev/tty
export DEBIAN_FRONTEND=noninteractive
export LC_ALL=C.UTF-8

# ---------------------------------------------------------------------------
#  Kleuren en vormen
# ---------------------------------------------------------------------------
R="" B="" D="" ERTS="" ERTS_BG="" INKT="" ROOD="" GROEN="" GEEL=""
VERLOOP=("" "" "" "" "" "")
KLEUR=0
kleuren() {
  if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then
    KLEUR=1
    R=$'\e[0m' B=$'\e[1m' D=$'\e[2m'
    if [[ "${COLORTERM:-}" == "truecolor" || "${COLORTERM:-}" == "24bit" ]]; then
      ERTS=$'\e[38;2;200;150;44m' ERTS_BG=$'\e[48;2;200;150;44m' INKT=$'\e[38;2;30;25;21m'
      ROOD=$'\e[38;2;226;92;68m' GROEN=$'\e[38;2;126;186;96m' GEEL=$'\e[38;2;232;184;84m'
      VERLOOP=($'\e[38;2;240;196;96m' $'\e[38;2;226;178;72m' $'\e[38;2;210;160;52m'
               $'\e[38;2;200;150;44m' $'\e[38;2;176;128;36m' $'\e[38;2;140;100;28m')
    else
      ERTS=$'\e[38;5;178m' ERTS_BG=$'\e[48;5;178m' INKT=$'\e[38;5;234m'
      ROOD=$'\e[38;5;167m' GROEN=$'\e[38;5;107m' GEEL=$'\e[38;5;222m'
      VERLOOP=($'\e[38;5;222m' $'\e[38;5;221m' $'\e[38;5;178m' $'\e[38;5;178m' $'\e[38;5;136m' $'\e[38;5;94m')
    fi
  fi
}

heeft_tty() { { : <"$TTY"; } 2>/dev/null; }

breedte() {
  local c=80
  if heeft_tty; then c=$( { stty size <"$TTY"; } 2>/dev/null | awk '{print $2}') || true; fi
  [[ "$c" =~ ^[0-9]+$ && "$c" -gt 20 ]] || c=80
  echo "$c"
}

lijn() { # teken, lengte
  local s
  printf -v s '%*s' "$2" ''
  printf '%s' "${s// /$1}"
}

woordmerk() { printf '%s%s%s Riant %s%sNode%s%s.%s' "$ERTS_BG" "$INKT" "$B" "$R" "$B" "$R" "$ERTS" "$R"; }

logo() {
  local -a L_R=('██████╗ ' '██╔══██╗' '██████╔╝' '██╔══██╗' '██║  ██║' '╚═╝  ╚═╝')
  local -a L_I=('██╗' '██║' '██║' '██║' '██║' '╚═╝')
  local -a L_A=(' █████╗ ' '██╔══██╗' '███████║' '██╔══██║' '██║  ██║' '╚═╝  ╚═╝')
  local -a L_N=('███╗   ██╗' '████╗  ██║' '██╔██╗ ██║' '██║╚██╗██║' '██║ ╚████║' '╚═╝  ╚═══╝')
  local -a L_T=('████████╗' '╚══██╔══╝' '   ██║   ' '   ██║   ' '   ██║   ' '   ╚═╝   ')
  local -a L_O=(' ██████╗ ' '██╔═══██╗' '██║   ██║' '██║   ██║' '╚██████╔╝' ' ╚═════╝ ')
  local -a L_D=('██████╗ ' '██╔══██╗' '██║  ██║' '██║  ██║' '██████╔╝' '╚═════╝ ')
  local -a L_E=('███████╗' '██╔════╝' '█████╗  ' '██╔══╝  ' '███████╗' '╚══════╝')
  local -a L_P=('   ' '   ' '   ' '   ' '██╗' '╚═╝')
  local i
  echo
  if [[ $(breedte) -ge 82 ]]; then
    for i in 0 1 2 3 4 5; do
      printf '  %s%s%s%s%s%s%s%s%s%s%s%s%s%s%s\n' \
        "${VERLOOP[$i]}" "$B" "${L_R[$i]}" "${L_I[$i]}" "${L_A[$i]}" "${L_N[$i]}" "${L_T[$i]}" "$R" \
        "$B" "${L_N[$i]}" "${L_O[$i]}" "${L_D[$i]}" "${L_E[$i]}" "$R$ERTS$B" "${L_P[$i]}$R"
    done
  else
    printf '  %s\n' "$(woordmerk)"
  fi
  echo
  printf '  %sPterodactyl-installer%s  %s·%s  panel, database, Wings en FiveM  %s·%s  %sv%s%s\n' \
    "$B" "$R" "$ERTS" "$R" "$ERTS" "$R" "$D" "$VERSIE" "$R"
  printf '  %s%s%s\n' "$ERTS" "$(lijn '━' $(( $(breedte) > 82 ? 78 : $(breedte) - 4 )))" "$R"
}

kop() {
  local w; w=$(breedte); (( w > 82 )) && w=82
  local t=" $1 "
  local rest=$(( w - ${#t} - 6 ))
  (( rest < 2 )) && rest=2
  printf '\n  %s%s▐█▌%s%s%s%s %s%s%s\n' "$ERTS_BG" "$INKT" "$R" "$B" "$t" "$R" "$D" "$(lijn '─' "$rest")" "$R"
}

info()  { printf '  %s●%s %s\n' "$ERTS" "$R" "$*"; }
goed()  { printf '  %s●%s %s\n' "$GROEN" "$R" "$*"; }
let_op(){ printf '  %s▲%s %s\n' "$GEEL" "$R" "$*"; }
fout()  { printf '  %s■%s %s%s%s\n' "$ROOD" "$R" "$B" "$*" "$R" >&2; }
grijs() { printf '    %s%s%s\n' "$D" "$*" "$R"; }

stop_met() { echo; fout "$1"; [[ -n "${2:-}" ]] && grijs "$2"; echo; exit 1; }

# ---------------------------------------------------------------------------
#  Vragen
# ---------------------------------------------------------------------------
NIET_INTERACTIEF=0

vraag() { # variabele, label, uitleg, standaard
  local __var=$1 label=$2 uitleg=$3 std=${4:-} antw=""
  if [[ -n "${!__var:-}" ]]; then return 0; fi
  if [[ $NIET_INTERACTIEF == 1 ]]; then printf -v "$__var" '%s' "$std"; return 0; fi
  printf '\n  %s▸%s %s%s%s\n' "$ERTS" "$R" "$B" "$label" "$R"
  [[ -n "$uitleg" ]] && printf '    %s%s%s\n' "$D" "$uitleg" "$R"
  if [[ -n "$std" ]]; then printf '    %s›%s %s[%s]%s ' "$ERTS" "$R" "$D" "$std" "$R"; else printf '    %s›%s ' "$ERTS" "$R"; fi
  IFS= read -r antw <"$TTY" || antw=""
  printf -v "$__var" '%s' "${antw:-$std}"
}

vraag_jn() { # variabele, label, uitleg, standaard j/n
  local __var=$1 label=$2 uitleg=$3 std=$4 antw=""
  if [[ -n "${!__var:-}" ]]; then
    case "${!__var}" in j|J|ja|y|yes|1|true) printf -v "$__var" j ;; *) printf -v "$__var" n ;; esac
    return 0
  fi
  if [[ $NIET_INTERACTIEF == 1 ]]; then printf -v "$__var" '%s' "$std"; return 0; fi
  local keuze="J/n"; [[ $std == n ]] && keuze="j/N"
  printf '\n  %s▸%s %s%s%s %s(%s)%s\n' "$ERTS" "$R" "$B" "$label" "$R" "$D" "$keuze" "$R"
  [[ -n "$uitleg" ]] && printf '    %s%s%s\n' "$D" "$uitleg" "$R"
  printf '    %s›%s ' "$ERTS" "$R"
  IFS= read -r antw <"$TTY" || antw=""
  antw=${antw:-$std}
  case "$antw" in j|J|ja|Ja|JA|y|Y|yes) printf -v "$__var" j ;; *) printf -v "$__var" n ;; esac
}

geheim() { # sterk wachtwoord, alleen letters en cijfers
  local s=""
  while (( ${#s} < 28 )); do
    s+=$(head -c 96 /dev/urandom | base64 -w0)
    s=${s//[^A-Za-z0-9]/}
  done
  printf '%s' "${s:0:28}"
}

# ---------------------------------------------------------------------------
#  Stappen met voortgang
# ---------------------------------------------------------------------------
STAP=0
STAPPEN=0
KIND=0

tijd() { printf '%d:%02d' $(( $1 / 60 )) $(( $1 % 60 )); }

balk() {
  local cellen=14 vol
  vol=$(( STAP * cellen / STAPPEN ))
  printf '%s%s%s%s%s' "$ERTS" "$(lijn '▰' "$vol")" "$D" "$(lijn '▱' $(( cellen - vol )))" "$R"
}

stap() { # titel, functie
  local titel=$1; shift
  STAP=$(( STAP + 1 ))
  local nr; printf -v nr '%02d/%02d' "$STAP" "$STAPPEN"
  printf '\n===== [%s] %s (%s) =====\n' "$nr" "$titel" "$(date '+%F %T')" >>"$LOG"
  ( set -Eeuo pipefail; "$@" ) >>"$LOG" 2>&1 &
  KIND=$!
  local start=$SECONDS frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏') i=0
  if [[ $KLEUR == 1 ]]; then
    printf '\e[?25l'
    while kill -0 "$KIND" 2>/dev/null; do
      printf '\r  %s%s%s  %s  %s%s%s  %-34s %s%s%s ' "$ERTS" "${frames[i]}" "$R" "$(balk)" "$D" "$nr" "$R" "$titel" "$D" "$(tijd $(( SECONDS - start )))" "$R"
      i=$(( (i + 1) % 10 ))
      sleep 0.1
    done
  else
    printf '  [%s] %s ... ' "$nr" "$titel"
  fi
  local code=0
  wait "$KIND" || code=$?
  KIND=0
  local duur; duur=$(tijd $(( SECONDS - start )))
  if [[ $code -eq 0 ]]; then
    if [[ $KLEUR == 1 ]]; then
      printf '\r  %s●%s  %s  %s%s%s  %-34s %s%s%s \n' "$GROEN" "$R" "$(balk)" "$D" "$nr" "$R" "$titel" "$D" "$duur" "$R"
    else
      printf 'klaar (%s)\n' "$duur"
    fi
  else
    if [[ $KLEUR == 1 ]]; then
      printf '\r  %s■%s  %s  %s%s%s  %s%-34s%s %s%s%s \n' "$ROOD" "$R" "$(balk)" "$D" "$nr" "$R" "$B" "$titel" "$R" "$D" "$duur" "$R"
      printf '\e[?25h'
    else
      printf 'mislukt (%s)\n' "$duur"
    fi
    echo
    fout "Deze stap is mislukt (code $code). De laatste regels uit het logboek:"
    echo
    tail -n 18 "$LOG" | sed "s/^/    ${D}│${R} /"
    echo
    grijs "Volledig logboek: $LOG"
    grijs "Je gegevens tot nu toe: $GEGEVENS"
    grijs "Kom je er niet uit? Open een issue op github.com/ITCompleet/riantnode-installer met dit logboek erbij."
    echo
    exit 1
  fi
}

opruimen() {
  local code=$?
  if [[ $KIND -gt 0 ]]; then kill "$KIND" 2>/dev/null || true; fi
  [[ $KLEUR == 1 ]] && printf '\e[?25h'
  rm -f "$WERKMAP/helper.php" 2>/dev/null || true
  exit "$code"
}
trap opruimen EXIT
trap 'echo; fout "Afgebroken."; exit 130' INT TERM

# ---------------------------------------------------------------------------
#  Hulp
# ---------------------------------------------------------------------------
hulp() {
  kleuren
  logo
  cat <<EOF

  ${B}Gebruik${R}
    bash install.sh              drie vragen (wat, domein, e-mail), de rest gaat vanzelf
    bash install.sh --help       deze uitleg

  ${B}Anders dan standaard, of helemaal zonder vragen${R}
    Geef het mee als omgevingsvariabele. Met RN_JA=1 stelt hij geen enkele vraag:

    RN_MODUS        alles | panel | wings                 (standaard: alles)
    RN_DOMEIN       domein van panel en node, leeg = alleen IP zonder SSL
    RN_EMAIL        e-mail van de beheerder, ook voor Let's Encrypt
    RN_GEBRUIKER    gebruikersnaam van de beheerder        (standaard: beheer)
    RN_WACHTWOORD   wachtwoord van de beheerder            (leeg = sterk, gegenereerd)
    RN_TIJDZONE     tijdzone                               (standaard: Europe/Amsterdam)
    RN_SSL          j/n  certificaat via Let's Encrypt     (standaard: j met domein)
    RN_FIREWALL     j/n  firewall (ufw) instellen          (standaard: j)
    RN_FIVEM        j/n  FiveM-egg importeren              (standaard: j)
    RN_POORTEN      poortreeksen voor servers              (standaard: ${STD_POORTEN})
    RN_KOPPEL       bij RN_MODUS=wings: het commando uit het panel (Configuration, Auto-deploy)

  ${B}Voorbeeld${R}
    RN_JA=1 RN_DOMEIN=panel.voorbeeld.nl RN_EMAIL=jij@voorbeeld.nl bash install.sh

  Met een domein vraagt de installer zelf een certificaat aan bij Let's Encrypt.
  Daarmee ga je akkoord met hun voorwaarden: letsencrypt.org/repository

EOF
}

# ---------------------------------------------------------------------------
#  Controles vooraf
# ---------------------------------------------------------------------------
OS_ID="" OS_VERSIE="" OS_NAAM="" ARCH="" PV="" PHP="" REDIS=""
PANEEL_TAG="" WINGS_TAG="" PUBLIEK_IP="" LOKAAL_IP=""

controleer_systeem() {
  [[ $EUID -eq 0 ]] || stop_met "Draai de installer als root." "Bijvoorbeeld: sudo bash install.sh"
  [[ -r /etc/os-release ]] || stop_met "Kan het besturingssysteem niet bepalen (geen /etc/os-release)."
  # shellcheck disable=SC1091
  . /etc/os-release
  OS_ID=${ID:-} OS_VERSIE=${VERSION_ID:-} OS_NAAM=${PRETTY_NAME:-onbekend}
  case "$OS_ID:$OS_VERSIE" in
    debian:12)    PV=8.2 ;;   # PHP 8.2 uit Debian zelf
    debian:13)    PV=8.3 ;;   # Debian 13 heeft 8.4, Pterodactyl 1.x wil 8.2 of 8.3: via packages.sury.org
    ubuntu:22.04) PV=8.3 ;;   # via ppa:ondrej/php
    ubuntu:24.04) PV=8.3 ;;   # PHP 8.3 uit Ubuntu zelf
    *) stop_met "$OS_NAAM wordt niet ondersteund." "Wel: Debian 12 en 13, Ubuntu 22.04 en 24.04. Liever eerlijk stoppen dan half installeren." ;;
  esac
  PHP="php$PV"
  case "$(uname -m)" in
    x86_64) ARCH=amd64 ;;
    aarch64|arm64) ARCH=arm64 ;;
    *) stop_met "Processor $(uname -m) wordt niet ondersteund (alleen x86_64 en arm64)." ;;
  esac
  if [[ $NIET_INTERACTIEF == 0 ]] && ! heeft_tty; then
    stop_met "Geen terminal om vragen te stellen." "Draai interactief, of gebruik RN_JA=1 met de variabelen uit --help."
  fi
  command -v curl >/dev/null || stop_met "curl ontbreekt." "Installeer het eerst: apt-get install -y curl"
  curl -fsS --max-time 10 -o /dev/null https://api.github.com || stop_met "Geen verbinding met GitHub." "De installer haalt Pterodactyl daar op; controleer de internetverbinding en DNS."
}

laatste_versie() { # repo -> laatste stabiele v1.x.y
  curl -fsSL --max-time 15 "https://api.github.com/repos/$1/releases?per_page=40" \
    | grep -oE '"tag_name": *"v1\.[0-9]+\.[0-9]+"' | grep -oE 'v1\.[0-9]+\.[0-9]+' | sort -V | tail -n 1
}

meet_omgeving() {
  PUBLIEK_IP=$(curl -4 -fsS --max-time 6 https://api.ipify.org 2>/dev/null || true)
  LOKAAL_IP=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}' || true)
  [[ -n "$LOKAAL_IP" ]] || LOKAAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  [[ -n "$PUBLIEK_IP" ]] || PUBLIEK_IP=$LOKAAL_IP
  PANEEL_TAG=$(laatste_versie pterodactyl/panel || true)
  WINGS_TAG=$(laatste_versie pterodactyl/wings || true)
  [[ -n "$PANEEL_TAG" && -n "$WINGS_TAG" ]] || stop_met "Kon de laatste Pterodactyl-versie niet ophalen bij GitHub." "Mogelijk de limiet van de GitHub-API (60 per uur per IP). Probeer het straks opnieuw."
}

ram_mb()   { awk '/MemTotal/{print int($2/1024)}' /proc/meminfo; }
schijf_mb(){ mkdir -p /var/lib/pterodactyl; df -Pm /var/lib/pterodactyl | awk 'NR==2{print int($4*0.9)}'; }

dns_van() { getent ahostsv4 "$1" 2>/dev/null | awk 'NR==1{print $1}'; }

# ---------------------------------------------------------------------------
#  Vragenronde
# ---------------------------------------------------------------------------
RN_MODUS=${RN_MODUS:-} RN_DOMEIN=${RN_DOMEIN:-} RN_EMAIL=${RN_EMAIL:-} RN_GEBRUIKER=${RN_GEBRUIKER:-}
RN_WACHTWOORD=${RN_WACHTWOORD:-} RN_TIJDZONE=${RN_TIJDZONE:-} RN_SSL=${RN_SSL:-}
RN_FIREWALL=${RN_FIREWALL:-} RN_FIVEM=${RN_FIVEM:-} RN_POORTEN=${RN_POORTEN:-} RN_KOPPEL=${RN_KOPPEL:-}
PANEEL_URL="" NODE_FQDN="" SCHEME="" WW_GEGENEREERD=n DB_WW="" DBH_WW=""

kies_modus() {
  if [[ -n "$RN_MODUS" ]]; then
    case "$RN_MODUS" in alles|panel|wings) return 0 ;; *) stop_met "RN_MODUS moet alles, panel of wings zijn." ;; esac
  fi
  if [[ $NIET_INTERACTIEF == 1 ]]; then RN_MODUS=alles; return 0; fi
  kop "Wat wil je installeren?"
  echo
  printf '   %s%s 1 %s  %sAlles op deze server%s %s(aanbevolen)%s\n' "$ERTS_BG" "$INKT$B" "$R" "$B" "$R" "$ERTS" "$R"
  grijs "    Panel, database, Wings en de FiveM-egg, meteen aan elkaar gekoppeld."
  printf '   %s%s 2 %s  %sAlleen het panel%s\n' "$ERTS_BG" "$INKT$B" "$R" "$B" "$R"
  grijs "    Panel met database, Redis en webserver. Wings komt op een andere server."
  printf '   %s%s 3 %s  %sAlleen Wings%s\n' "$ERTS_BG" "$INKT$B" "$R" "$B" "$R"
  grijs "    Een extra node voor een panel dat al draait."
  local k=""
  while true; do
    printf '\n    %s›%s %s[1]%s ' "$ERTS" "$R" "$D" "$R"
    IFS= read -r k <"$TTY" || k=""
    case "${k:-1}" in 1) RN_MODUS=alles; break ;; 2) RN_MODUS=panel; break ;; 3) RN_MODUS=wings; break ;; *) let_op "Kies 1, 2 of 3." ;; esac
  done
}

vraag_domein() {
  local label="Domein voor het panel"
  [[ $RN_MODUS == wings ]] && label="Domein van deze node"
  while true; do
    vraag RN_DOMEIN "$label" "Bijvoorbeeld panel.jouwdomein.nl, met een A-record naar ${PUBLIEK_IP}. Leeg laten = alleen IP, zonder SSL." ""
    RN_DOMEIN=${RN_DOMEIN,,}
    RN_DOMEIN=${RN_DOMEIN#http://}; RN_DOMEIN=${RN_DOMEIN#https://}; RN_DOMEIN=${RN_DOMEIN%%/*}
    if [[ -z "$RN_DOMEIN" || "$RN_DOMEIN" =~ ^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,}$ ]]; then break; fi
    [[ $NIET_INTERACTIEF == 1 ]] && stop_met "RN_DOMEIN '$RN_DOMEIN' is geen geldig domein."
    let_op "Dat is geen geldig domein."; RN_DOMEIN=""
  done
}

controleer_dns() { # wijst het domein naar deze server? Zo niet: opnieuw meten of zonder SSL verder
  local wijst opnieuw
  while true; do
    wijst=$(dns_van "$RN_DOMEIN" || true)
    if [[ "$wijst" == "$PUBLIEK_IP" ]]; then
      goed "$RN_DOMEIN wijst naar deze server ($PUBLIEK_IP). Gemeten."
      return 0
    fi
    echo
    if [[ -z "$wijst" ]]; then
      let_op "$RN_DOMEIN heeft (nog) geen A-record."
    else
      let_op "$RN_DOMEIN wijst naar $wijst, maar deze server is $PUBLIEK_IP."
      grijs "Gebruik je Cloudflare? Zet de wolk op grijs (DNS only): Wings en Let's Encrypt werken niet via de proxy."
    fi
    grijs "Maak een A-record van $RN_DOMEIN naar $PUBLIEK_IP. Zonder dat lukt het certificaat niet."
    [[ $NIET_INTERACTIEF == 1 ]] && stop_met "Het domein wijst niet naar deze server." "Zet de DNS goed, of laat RN_DOMEIN leeg voor een installatie op IP."
    opnieuw=""
    vraag_jn opnieuw "DNS aangepast? Opnieuw meten" "Kies n om zonder domein en SSL verder te gaan, op het IP-adres." j
    if [[ $opnieuw != j ]]; then
      RN_DOMEIN="" RN_SSL=n
      let_op "Dan zonder SSL, op $PUBLIEK_IP."
      return 0
    fi
  done
}

vraag_email() {
  while true; do
    vraag RN_EMAIL "E-mailadres" "$1" ""
    [[ "$RN_EMAIL" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[a-zA-Z]{2,}$ ]] && return 0
    [[ $NIET_INTERACTIEF == 1 ]] && stop_met "RN_EMAIL ontbreekt of is ongeldig."
    let_op "Dat is geen geldig e-mailadres."; RN_EMAIL=""
  done
}

ja_nee() { # zet een opgegeven variabele om naar j/n, met standaard
  local __var=$1 std=$2
  case "${!__var:-$std}" in j|J|ja|y|yes|1|true) printf -v "$__var" j ;; *) printf -v "$__var" n ;; esac
}

vragenronde() {
  # Zo min mogelijk vragen: wat, domein, e-mail. De rest heeft een goede standaard en is te wijzigen via RN_*-variabelen.
  kies_modus

  kop "Adres"
  vraag_domein
  if [[ -n "$RN_DOMEIN" ]]; then
    ja_nee RN_SSL j
    [[ $RN_SSL == j ]] && controleer_dns
  else
    RN_SSL=n
  fi
  if [[ $RN_SSL == j ]]; then SCHEME=https; else SCHEME=http; fi
  if [[ -n "$RN_DOMEIN" ]]; then NODE_FQDN=$RN_DOMEIN; else NODE_FQDN=$PUBLIEK_IP; fi
  PANEEL_URL="$SCHEME://$NODE_FQDN"

  if [[ $RN_MODUS != wings ]]; then
    kop "Jouw account"
    vraag_email "Je logt hiermee in op het panel. Let's Encrypt mailt hierheen als verlengen misgaat."
    RN_GEBRUIKER=${RN_GEBRUIKER:-beheer}
    [[ "$RN_GEBRUIKER" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]{2,190}$ ]] || stop_met "RN_GEBRUIKER '$RN_GEBRUIKER' is ongeldig."
    if [[ -z "$RN_WACHTWOORD" ]]; then RN_WACHTWOORD=$(geheim); WW_GEGENEREERD=j; fi
    if [[ -z "$RN_TIJDZONE" ]]; then
      RN_TIJDZONE=$(timedatectl show -p Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || true)
      [[ -z "$RN_TIJDZONE" || "$RN_TIJDZONE" == "Etc/UTC" || "$RN_TIJDZONE" == "UTC" ]] && RN_TIJDZONE="Europe/Amsterdam"
    fi
    [[ -e "/usr/share/zoneinfo/$RN_TIJDZONE" ]] || stop_met "Tijdzone '$RN_TIJDZONE' bestaat niet."
  fi

  if [[ $RN_MODUS == wings ]]; then
    RN_FIVEM=n
  elif [[ $ARCH == arm64 && $RN_MODUS == alles ]]; then
    RN_FIVEM=n
  else
    ja_nee RN_FIVEM j
  fi
  ja_nee RN_FIREWALL j
  RN_POORTEN=${RN_POORTEN:-$STD_POORTEN}
  local p
  for p in $RN_POORTEN; do
    [[ "$p" =~ ^[0-9]{2,5}(-[0-9]{2,5})?$ ]] || stop_met "Poortreeks '$p' klopt niet." "Schrijf het als 30120-30129 of als losse poort 25565."
  done

  if [[ $RN_MODUS == wings ]]; then
    kop "Koppelen"
    vraag RN_KOPPEL "Plak het koppelcommando uit je panel (mag leeg)" "Panel > Admin > Nodes > jouw node > Configuration > Generate Token. Leeg = later zelf koppelen." ""
  fi
}

samenvatting() {
  kop "Klaar om te installeren"
  echo
  local -a rijen=()
  local fivem="" ssl="geen" fw="niet aanraken"
  [[ $RN_FIVEM == j ]] && fivem=" en de FiveM-egg"
  [[ $RN_SSL == j ]] && ssl="Let's Encrypt"
  [[ $RN_FIREWALL == j ]] && fw="ufw aan, alleen de nodige poorten open"
  case $RN_MODUS in
    alles) rijen+=("Wat|Panel, database, Wings${fivem}") ;;
    panel) rijen+=("Wat|Alleen het panel${fivem}") ;;
    wings) rijen+=("Wat|Alleen Wings") ;;
  esac
  rijen+=("Systeem|$OS_NAAM ($ARCH)")
  [[ $RN_MODUS != wings ]] && rijen+=("Pterodactyl|panel $PANEEL_TAG, PHP $PV")
  [[ $RN_MODUS != panel ]] && rijen+=("Wings|$WINGS_TAG met Docker")
  rijen+=("Adres|$PANEEL_URL")
  rijen+=("SSL|$ssl")
  if [[ $RN_MODUS != wings ]]; then
    if [[ $WW_GEGENEREERD == j ]]; then rijen+=("Beheerder|$RN_GEBRUIKER ($RN_EMAIL), sterk wachtwoord dat je aan het eind ziet")
    else rijen+=("Beheerder|$RN_GEBRUIKER ($RN_EMAIL)"); fi
  fi
  [[ $RN_MODUS != wings ]] && rijen+=("Tijdzone|$RN_TIJDZONE")
  [[ $RN_MODUS != panel ]] && rijen+=("Poorten|$RN_POORTEN")
  rijen+=("Firewall|$fw")
  local rij
  for rij in "${rijen[@]}"; do
    printf '    %s%-13s%s %s\n' "$D" "${rij%%|*}" "$R" "${rij#*|}"
  done
  if [[ $RN_MODUS == alles && $RN_FIREWALL != j ]]; then
    echo
    let_op "Zonder firewall is MariaDB (poort 3306) van buitenaf bereikbaar, want gameservers hebben hem nodig."
    grijs "Zet zelf poort 3306 dicht voor alles behalve 172.18.0.0/16, of laat de firewall aan."
  fi
  echo
  if [[ $RN_SSL == j ]]; then
    grijs "Met Starten ga je akkoord met de voorwaarden van Let's Encrypt (letsencrypt.org/repository)."
  fi
  grijs "Duurt meestal 5 tot 10 minuten. Alles wat er gebeurt komt in $LOG."
  grijs "Wachtwoorden komen in $GEGEVENS (alleen leesbaar voor root)."
  if [[ $NIET_INTERACTIEF == 0 ]]; then
    local ga=""
    vraag_jn ga "Starten?" "" j
    [[ $ga == j ]] || { echo; info "Niets gedaan. Tot een volgende keer."; echo; exit 0; }
  fi
}

# ---------------------------------------------------------------------------
#  Hulpscript voor het panel (draait als www-data, geheimen via de omgeving)
# ---------------------------------------------------------------------------
schrijf_helper() {
  mkdir -p "$WERKMAP"
  cat >"$WERKMAP/helper.php" <<'PHP'
<?php
// RiantNode installer: kleine handelingen in Pterodactyl via de eigen services van het panel.
require '/var/www/pterodactyl/vendor/autoload.php';
$app = require '/var/www/pterodactyl/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$actie = $argv[1] ?? '';

// Laravel vangt een losse uitzondering zelf af en eindigt dan met exit 0 (gemeten 24-11-2026, panel 1.15.2).
// Daarom vangen we alles hier en stoppen we zelf met exit 1, anders wordt een mislukte stap groen.
try {
    rn_actie($app, $actie, $argv);
} catch (Throwable $e) {
    fwrite(STDERR, get_class($e) . ': ' . $e->getMessage() . "\n");
    exit(1);
}
exit(0);

function rn_actie($app, string $actie, array $argv): void
{
if ($actie === 'gebruiker') {
    $email = getenv('RN_H_EMAIL');
    $naam = getenv('RN_H_GEBRUIKER');
    if (Pterodactyl\Models\User::query()->where('email', $email)->orWhere('username', $naam)->exists()) {
        echo "Gebruiker bestaat al, niets gedaan\n";
        return;
    }
    $app->make(Pterodactyl\Services\Users\UserCreationService::class)->handle([
        'email' => $email,
        'username' => $naam,
        'name_first' => 'Beheer',
        'name_last' => 'Paneel',
        'password' => getenv('RN_H_WW'),
        'root_admin' => true,
    ]);
    echo "Beheerder aangemaakt: $naam\n";
    return;
}

if ($actie === 'egg') {
    $pad = $argv[2];
    $nestNaam = $argv[3];
    $nest = Pterodactyl\Models\Nest::query()->where('name', $nestNaam)->first()
        ?? $app->make(Pterodactyl\Services\Nests\NestCreationService::class)->handle([
            'name' => $nestNaam,
            'description' => 'Geimporteerd door de RiantNode-installer.',
        ]);
    $bestand = new Illuminate\Http\UploadedFile($pad, basename($pad), 'application/json', null, true);
    $naam = json_decode(file_get_contents($pad), true)['name'] ?? '';
    $bestaand = Pterodactyl\Models\Egg::query()->where('nest_id', $nest->id)->where('name', $naam)->first();
    if ($bestaand) {
        $app->make(Pterodactyl\Services\Eggs\Sharing\EggUpdateImporterService::class)->handle($bestaand, $bestand);
        echo "Egg bijgewerkt: $naam (nest $nestNaam)\n";
    } else {
        $egg = $app->make(Pterodactyl\Services\Eggs\Sharing\EggImporterService::class)->handle($bestand, $nest->id);
        echo "Egg geimporteerd: {$egg->name} (nest $nestNaam, id {$egg->id})\n";
    }
    return;
}

if ($actie === 'dbhost') {
    $host = $argv[2];
    if (Pterodactyl\Models\DatabaseHost::query()->where('host', $host)->exists()) {
        echo "Databasehost bestaat al, niets gedaan\n";
        return;
    }
    $app->make(Pterodactyl\Services\Databases\Hosts\HostCreationService::class)->handle([
        'name' => 'Deze server',
        'host' => $host,
        'port' => 3306,
        'username' => getenv('RN_H_GEBRUIKER'),
        'password' => getenv('RN_H_WW'),
        'node_id' => (int) $argv[3],
    ]);
    echo "Databasehost toegevoegd: $host\n";
    return;
}

throw new InvalidArgumentException("Onbekende actie: $actie");
}
PHP
  chmod 644 "$WERKMAP/helper.php"
  chmod 755 "$WERKMAP"
}

als_www() { (cd "$PANEEL" && runuser -u www-data -- "$PHP" "$@"); }
artisan() { (cd "$PANEEL" && "$PHP" artisan -n "$@"); }
sql()     { mysql -N -B panel -e "$1"; }

apt_in() { apt-get -y -q -o DPkg::Lock::Timeout=300 -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold install "$@"; }

# ---------------------------------------------------------------------------
#  De stappen zelf
# ---------------------------------------------------------------------------
s_basis() {
  apt-get -q -o DPkg::Lock::Timeout=300 update
  apt_in ca-certificates curl gnupg lsb-release tar unzip git cron openssl
}

s_php_bron() {
  case "$OS_ID:$OS_VERSIE" in
    debian:13)
      curl -fsSL -o /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg
      echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" \
        >/etc/apt/sources.list.d/php-sury.list
      ;;
    ubuntu:22.04)
      apt_in software-properties-common
      LC_ALL=C.UTF-8 add-apt-repository -y ppa:ondrej/php
      ;;
    *) echo "PHP $PV komt uit de eigen bronnen van $OS_NAAM, geen extra bron nodig" ;;
  esac
  apt-get -q -o DPkg::Lock::Timeout=300 update
}

s_pakketten() {
  if apt-cache show redis-server >/dev/null 2>&1; then REDIS="redis-server"; else REDIS="valkey-server"; fi
  echo "$REDIS" >"$WERKMAP/redis"
  apt_in "$PHP"-{common,cli,gd,mysql,mbstring,bcmath,xml,fpm,curl,zip} mariadb-server nginx "$REDIS"
  systemctl enable --now mariadb nginx "$PHP-fpm" "$REDIS"
  "$PHP" -v
}

s_composer() {
  local verwacht echt
  verwacht=$(curl -fsSL https://composer.github.io/installer.sig)
  curl -fsSL -o "$WERKMAP/composer-setup.php" https://getcomposer.org/installer
  echt=$("$PHP" -r "echo hash_file('sha384', '$WERKMAP/composer-setup.php');")
  if [[ "$verwacht" != "$echt" ]]; then echo "Controlesom van de Composer-installer klopt niet"; return 1; fi
  "$PHP" "$WERKMAP/composer-setup.php" --quiet --install-dir=/usr/local/bin --filename=composer
  rm -f "$WERKMAP/composer-setup.php"
}

s_paneel_downloaden() {
  mkdir -p "$PANEEL"
  curl -fL --retry 3 -o "$WERKMAP/panel.tar.gz" "https://github.com/pterodactyl/panel/releases/download/$PANEEL_TAG/panel.tar.gz"
  tar -xzf "$WERKMAP/panel.tar.gz" -C "$PANEEL"
  rm -f "$WERKMAP/panel.tar.gz"
  chmod -R 755 "$PANEEL"/storage/* "$PANEEL"/bootstrap/cache/
}

s_database() {
  mysql <<SQL
CREATE USER IF NOT EXISTS 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_WW}';
ALTER USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '${DB_WW}';
CREATE DATABASE IF NOT EXISTS panel;
GRANT ALL PRIVILEGES ON panel.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
SQL
  echo "Database 'panel' en gebruiker 'pterodactyl' staan klaar"
}

env_zet() {
  local f="$PANEEL/.env"
  if grep -q "^$1=" "$f"; then sed -i "s|^$1=.*|$1=$2|" "$f"; else echo "$1=$2" >>"$f"; fi
}

s_paneel_instellen() {
  cd "$PANEEL"
  [[ -f .env ]] || cp .env.example .env
  COMPOSER_ALLOW_SUPERUSER=1 "$PHP" /usr/local/bin/composer install --no-dev --optimize-autoloader --no-interaction --no-progress
  if ! grep -q '^APP_KEY=base64:' .env; then artisan key:generate --force; fi
  # Let op: --telemetry=false zet telemetrie in 1.x juist AAN (operatorvolgorde in AppSettingsCommand); 0 werkt wel.
  artisan p:environment:setup --author="$RN_EMAIL" --url="$PANEEL_URL" --timezone="$RN_TIJDZONE" \
    --cache=redis --session=redis --queue=redis --redis-host=127.0.0.1 --redis-pass= --redis-port=6379 \
    --settings-ui=true --telemetry=0
  env_zet DB_CONNECTION mysql
  env_zet DB_HOST 127.0.0.1
  env_zet DB_PORT 3306
  env_zet DB_DATABASE panel
  env_zet DB_USERNAME pterodactyl
  env_zet DB_PASSWORD "$DB_WW"
  artisan config:clear
  artisan migrate --seed --force
  chown -R www-data:www-data "$PANEEL"
  RN_H_EMAIL=$RN_EMAIL RN_H_GEBRUIKER=$RN_GEBRUIKER RN_H_WW=$RN_WACHTWOORD als_www "$WERKMAP/helper.php" gebruiker
  [[ "$(sql "SELECT COUNT(*) FROM users WHERE username='${RN_GEBRUIKER}' AND root_admin=1")" == "1" ]] \
    || { echo "Controle: beheerder staat niet in de database"; return 1; }
}

s_achtergrond() {
  local redis; redis=$(cat "$WERKMAP/redis")
  cat >/etc/systemd/system/pteroq.service <<EOF
# Gemaakt door de RiantNode-installer
[Unit]
Description=Pterodactyl Queue Worker
After=${redis}.service

[Service]
User=www-data
Group=www-data
Restart=always
ExecStart=/usr/bin/${PHP} ${PANEEL}/artisan queue:work --queue=high,standard,low --sleep=3 --tries=3
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
  echo "* * * * * www-data /usr/bin/${PHP} ${PANEEL}/artisan schedule:run >> /dev/null 2>&1" >/etc/cron.d/pterodactyl
  chmod 644 /etc/cron.d/pterodactyl
  systemctl daemon-reload
  systemctl enable --now pteroq.service
}

s_certificaat() {
  local le_mail=(--register-unsafely-without-email)
  [[ -n "$RN_EMAIL" ]] && le_mail=(--email "$RN_EMAIL")
  apt_in certbot
  systemctl stop nginx 2>/dev/null || true
  certbot certonly --standalone --non-interactive --agree-tos --no-eff-email \
    -d "$RN_DOMEIN" "${le_mail[@]}" \
    --pre-hook "systemctl stop nginx 2>/dev/null || true" \
    --post-hook "systemctl start nginx 2>/dev/null || true" \
    --deploy-hook "systemctl restart wings 2>/dev/null || true" \
    || { systemctl start nginx 2>/dev/null || true; return 1; }
  systemctl start nginx 2>/dev/null || true
  test -s "/etc/letsencrypt/live/$RN_DOMEIN/fullchain.pem"
}

s_webserver() {
  local conf=/etc/nginx/sites-available/pterodactyl.conf
  if [[ $RN_SSL == j ]]; then
    cat >"$conf" <<'NGINX'
# Gemaakt door de RiantNode-installer
server {
    listen 80;
    server_name __NAAM__;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name __NAAM__;

    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.app-access.log;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    ssl_certificate /etc/letsencrypt/live/__NAAM__/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/__NAAM__/privkey.pem;
    ssl_session_cache shared:SSL:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384";
    ssl_prefer_server_ciphers on;

    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header X-Robots-Tag none;
    add_header Content-Security-Policy "frame-ancestors 'self'";
    add_header X-Frame-Options DENY;
    add_header Referrer-Policy same-origin;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php__PV__-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINX
  else
    cat >"$conf" <<'NGINX'
# Gemaakt door de RiantNode-installer
server {
    listen 80 default_server;
    server_name __NAAM__;

    root /var/www/pterodactyl/public;
    index index.html index.htm index.php;
    charset utf-8;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location = /favicon.ico { access_log off; log_not_found off; }
    location = /robots.txt  { access_log off; log_not_found off; }

    access_log off;
    error_log  /var/log/nginx/pterodactyl.app-error.log error;

    client_max_body_size 100m;
    client_body_timeout 120s;
    sendfile off;

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/run/php/php__PV__-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param PHP_VALUE "upload_max_filesize = 100M \n post_max_size=100M";
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
        fastcgi_connect_timeout 300;
        fastcgi_send_timeout 300;
        fastcgi_read_timeout 300;
    }

    location ~ /\.ht {
        deny all;
    }
}
NGINX
  fi
  sed -i "s|__NAAM__|${NODE_FQDN}|g; s|__PV__|${PV}|g" "$conf"
  rm -f /etc/nginx/sites-enabled/default
  ln -sf "$conf" /etc/nginx/sites-enabled/pterodactyl.conf
  nginx -t
  systemctl restart nginx
}

s_docker() {
  if command -v docker >/dev/null 2>&1; then
    echo "Docker staat er al: $(docker --version)"
  else
    curl -fsSL https://get.docker.com -o "$WERKMAP/get-docker.sh"
    sh "$WERKMAP/get-docker.sh"
    rm -f "$WERKMAP/get-docker.sh"
  fi
  systemctl enable --now docker
  docker info >/dev/null
}

s_wings() {
  mkdir -p /etc/pterodactyl /var/lib/pterodactyl/volumes
  curl -fL --retry 3 -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/download/$WINGS_TAG/wings_linux_$ARCH"
  chmod 755 /usr/local/bin/wings
  /usr/local/bin/wings version
  cat >/etc/systemd/system/wings.service <<'EOF'
# Gemaakt door de RiantNode-installer
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service
PartOf=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=on-failure
StartLimitInterval=180
StartLimitBurst=30
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable wings
}

wacht_op_wings() {
  local i
  for i in $(seq 1 45); do
    if systemctl is-active --quiet wings && ip -4 addr show pterodactyl0 >/dev/null 2>&1; then
      echo "Wings draait en het Docker-netwerk pterodactyl0 bestaat (na ${i}s)"
      return 0
    fi
    sleep 1
  done
  systemctl status wings --no-pager || true
  journalctl -u wings -n 40 --no-pager || true
  if journalctl -u wings -n 3 --no-pager 2>/dev/null | grep -q 'fetching list of servers'; then
    echo
    echo ">> Wings kan het panel niet bereiken op $(awk '/^remote:/{print $2}' /etc/pterodactyl/config.yml)."
    echo ">> Controleer of dat adres vanaf deze server antwoordt: curl -I <adres>"
  fi
  return 1
}

poorten_sql() { # node-id, ip, alias
  local node=$1 ip=$2 alias=$3 reeks van tot p waarden=""
  local alias_sql="NULL"; [[ -n "$alias" ]] && alias_sql="'$alias'"
  for reeks in $RN_POORTEN; do
    van=${reeks%-*}; tot=${reeks#*-}
    for (( p=van; p<=tot; p++ )); do
      waarden+="(${node},'${ip}',${alias_sql},${p},NOW(),NOW()),"
    done
  done
  echo "INSERT INTO allocations (node_id, ip, ip_alias, port, created_at, updated_at) VALUES ${waarden%,};"
}

s_node_koppelen() {
  local loc node alias=""
  loc=$(sql "SELECT id FROM locations WHERE short='hoofd' LIMIT 1")
  if [[ -z "$loc" ]]; then
    artisan p:location:make --short=hoofd --long="Hoofdlocatie"
    loc=$(sql "SELECT id FROM locations WHERE short='hoofd' LIMIT 1")
  fi
  local naam; naam=$(hostname -s)
  node=$(sql "SELECT id FROM nodes WHERE name='${naam}' LIMIT 1")
  if [[ -z "$node" ]]; then
    artisan p:node:make --name="$naam" --description="Gemaakt door de RiantNode-installer" --locationId="$loc" \
      --fqdn="$NODE_FQDN" --public=1 --scheme="$SCHEME" --proxy=0 --maintenance=0 \
      --maxMemory="$(ram_mb)" --overallocateMemory=0 --maxDisk="$(schijf_mb)" --overallocateDisk=0 \
      --uploadSize=100 --daemonListeningPort=8080 --daemonSFTPPort=2022 --daemonBase=/var/lib/pterodactyl/volumes
    node=$(sql "SELECT id FROM nodes WHERE name='${naam}' LIMIT 1")
  fi
  [[ -n "$node" ]] || { echo "Node is niet aangemaakt"; return 1; }
  echo "$node" >"$WERKMAP/node"
  artisan p:node:configuration "$node" >"$WERKMAP/config.yml"
  grep -q '^uuid:' "$WERKMAP/config.yml" || { echo "Onverwachte uitvoer van p:node:configuration:"; cat "$WERKMAP/config.yml"; return 1; }
  install -m 600 "$WERKMAP/config.yml" /etc/pterodactyl/config.yml
  rm -f "$WERKMAP/config.yml"
  # Panel en Wings staan op dezelfde server: Wings praat lokaal met het panel. Achter NAT (thuis, sommige clouds)
  # komt verkeer naar het eigen publieke IP namelijk niet terug (hairpin-NAT) en blijft Wings eindeloos wachten.
  if [[ $RN_SSL == j ]]; then
    grep -qE "^127\.0\.0\.1[[:space:]].*[[:space:]]${RN_DOMEIN//./\\.}([[:space:]]|$)" /etc/hosts \
      || echo "127.0.0.1 ${RN_DOMEIN} # RiantNode-installer: Wings praat lokaal met het panel" >>/etc/hosts
  else
    sed -i "s|^remote: .*|remote: 'http://127.0.0.1'|" /etc/pterodactyl/config.yml
    # Wings gebruikt zijn remote ook als de toegestane origin voor de browser (CORS). Met remote op 127.0.0.1
    # weigert hij het panel op het publieke IP: rood hartje, geen console, geen bestanden (gevonden 26-11 op
    # Ubuntu 24.04 bij Rik). Daarom het panel-adres er uitdrukkelijk bij.
    # De regel staat er vóór de eerste start van Wings meestal nog niet in (Wings vult zijn standaarden pas bij het
    # starten aan); dan zelf toevoegen. Wings laat een bestaande waarde staan. Getest 26-11 op Ubuntu 24.04.
    if ! grep -q '^allowed_origins:' /etc/pterodactyl/config.yml; then
      printf 'allowed_origins:\n- %s\n' "$PANEEL_URL" >>/etc/pterodactyl/config.yml
    elif grep -q '^allowed_origins: \[\]' /etc/pterodactyl/config.yml; then
      sed -i "s|^allowed_origins: \[\]|allowed_origins:\n- ${PANEEL_URL}|" /etc/pterodactyl/config.yml
    elif ! grep -qF -- "- ${PANEEL_URL}" /etc/pterodactyl/config.yml; then
      sed -i "/^allowed_origins:/a - ${PANEEL_URL}" /etc/pterodactyl/config.yml
    fi
  fi
  grep '^remote:' /etc/pterodactyl/config.yml
  if [[ "$(sql "SELECT COUNT(*) FROM allocations WHERE node_id=${node}")" == "0" ]]; then
    [[ "$PUBLIEK_IP" != "$LOKAAL_IP" ]] && alias=$PUBLIEK_IP
    sql "$(poorten_sql "$node" "$LOKAAL_IP" "$alias")"
    echo "Poorten toegevoegd op $LOKAAL_IP${alias:+ (alias $alias)}: $RN_POORTEN"
  fi
  chown -R www-data:www-data "$PANEEL"
  systemctl restart wings
  wacht_op_wings
}

s_dbhost() {
  local node; node=$(cat "$WERKMAP/node")
  cat >/etc/mysql/mariadb.conf.d/99-riantnode.cnf <<'EOF'
# Gemaakt door de RiantNode-installer: gameservers in Docker (172.18.0.0/16) mogen bij MariaDB.
[mysqld]
bind-address = 0.0.0.0
# Zonder dit zoekt MariaDB bij 172.18.0.1 de hostnaam van de server op en past de gebruiker op 172.18.0.% niet meer.
skip-name-resolve = 1
EOF
  systemctl restart mariadb
  # Twee ingangen: gameservers komen uit Docker (172.18.0.%), het panel komt binnen vanaf het eigen IP van de
  # server, niet vanaf 172.18.0.1 (gemeten 24-11-2026). Poort 3306 staat in de firewall alleen open voor Docker.
  local h
  for h in '172.18.0.%' "$LOKAAL_IP"; do
    mysql <<SQL
CREATE USER IF NOT EXISTS 'riantnode'@'${h}' IDENTIFIED BY '${DBH_WW}';
ALTER USER 'riantnode'@'${h}' IDENTIFIED BY '${DBH_WW}';
GRANT ALL PRIVILEGES ON *.* TO 'riantnode'@'${h}' WITH GRANT OPTION;
SQL
  done
  mysql -e 'FLUSH PRIVILEGES;'
  RN_H_GEBRUIKER=riantnode RN_H_WW=$DBH_WW als_www "$WERKMAP/helper.php" dbhost 172.18.0.1 "$node"
  [[ "$(sql "SELECT COUNT(*) FROM database_hosts WHERE host='172.18.0.1'")" == "1" ]] \
    || { echo "Controle: databasehost staat niet in de database"; return 1; }
}

s_fivem() {
  curl -fsSL --retry 3 -o "$WERKMAP/egg-five-m.json" "$EGG_URL"
  # shellcheck disable=SC2016
  "$PHP" -r 'json_decode(file_get_contents($argv[1]), false, 512, JSON_THROW_ON_ERROR);' "$WERKMAP/egg-five-m.json"
  chmod 644 "$WERKMAP/egg-five-m.json"
  als_www "$WERKMAP/helper.php" egg "$WERKMAP/egg-five-m.json" FiveM
  rm -f "$WERKMAP/egg-five-m.json"
  [[ "$(sql "SELECT COUNT(*) FROM eggs e JOIN nests n ON n.id=e.nest_id WHERE n.name='FiveM'")" -ge 1 ]] \
    || { echo "Controle: FiveM-egg staat niet in de database"; return 1; }
}

s_wings_koppelen() {
  local url="" token="" node=""
  [[ "$RN_KOPPEL" =~ --panel-url[=\ ]+([^ ]+) ]] && url=${BASH_REMATCH[1]}
  [[ "$RN_KOPPEL" =~ --token[=\ ]+([^ ]+) ]] && token=${BASH_REMATCH[1]}
  [[ "$RN_KOPPEL" =~ --node[=\ ]+([0-9]+) ]] && node=${BASH_REMATCH[1]}
  if [[ -z "$url" || -z "$token" || -z "$node" ]]; then echo "Koppelcommando niet herkend (panel-url, token en node nodig)"; return 1; fi
  local extra=()
  [[ "$url" == http://* ]] && extra+=(--allow-insecure)
  (cd /etc/pterodactyl && /usr/local/bin/wings configure --panel-url "$url" --token "$token" --node "$node" "${extra[@]}")
  systemctl restart wings
  wacht_op_wings
}

ssh_poorten() {
  local p; p=$(sshd -T 2>/dev/null | awk '$1=="port"{print $2}' | sort -u || true)
  echo "${p:-22}"
}

s_firewall() {
  apt_in ufw
  local p reeks
  for p in $(ssh_poorten); do ufw allow "$p/tcp" comment 'SSH'; done
  if [[ $RN_MODUS != wings ]]; then
    ufw allow 80/tcp comment 'Panel'
    ufw allow 443/tcp comment 'Panel'
  elif [[ $RN_SSL == j ]]; then
    ufw allow 80/tcp comment 'Lets Encrypt'
  fi
  if [[ $RN_MODUS != panel ]]; then
    ufw allow 8080/tcp comment 'Wings'
    ufw allow 2022/tcp comment 'Wings SFTP'
    for reeks in $RN_POORTEN; do
      ufw allow "${reeks/-/:}/tcp" comment 'Gameservers'
      ufw allow "${reeks/-/:}/udp" comment 'Gameservers'
    done
  fi
  if [[ $RN_MODUS == alles ]]; then
    ufw allow from 172.18.0.0/16 to any port 3306 proto tcp comment 'MariaDB voor gameservers'
  fi
  ufw --force enable
  ufw status verbose
}

# ---------------------------------------------------------------------------
#  Na afloop: meten wat er echt draait
# ---------------------------------------------------------------------------
METINGEN=()
meet() { METINGEN+=("$1|$2|$3"); } # status(goed/let/fout), wat, uitkomst

eindcontrole() {
  local code
  if [[ $RN_MODUS != wings ]]; then
    if [[ $RN_SSL == j ]]; then
      code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 --resolve "$RN_DOMEIN:443:127.0.0.1" "https://$RN_DOMEIN/auth/login" || true)
    else
      code=$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "http://127.0.0.1/auth/login" || true)
    fi
    if [[ "$code" == "200" ]]; then meet goed "Panel" "inlogpagina antwoordt (HTTP 200)"; else meet fout "Panel" "inlogpagina gaf HTTP ${code:-geen antwoord}"; fi
    if systemctl is-active --quiet pteroq; then meet goed "Wachtrij" "pteroq draait"; else meet fout "Wachtrij" "pteroq draait niet"; fi
  fi
  if [[ $RN_MODUS != panel ]]; then
    if systemctl is-active --quiet wings; then
      code=$(curl -sk -o /dev/null -w '%{http_code}' --max-time 10 "$SCHEME://127.0.0.1:8080/api/system" || true)
      if [[ "$code" == "401" ]]; then meet goed "Wings" "draait, API antwoordt op 8080"
      else meet let "Wings" "draait, API gaf HTTP ${code:-geen antwoord}"; fi
    elif [[ $RN_MODUS == wings && -z "$RN_KOPPEL" ]]; then
      meet let "Wings" "geinstalleerd, wacht op koppeling met je panel"
    else
      meet fout "Wings" "draait niet"
    fi
  fi
  if [[ $RN_MODUS == alles ]] && systemctl is-active --quiet wings; then
    # Het hartje in het panel komt uit de browser: Wings moet het panel-adres als origin toestaan (26-11).
    local origin
    origin=$(curl -sk -o /dev/null -D - -X OPTIONS --max-time 10 "$SCHEME://127.0.0.1:8080/api/system" \
      -H "Origin: $PANEEL_URL" -H "Access-Control-Request-Method: GET" 2>/dev/null \
      | tr -d '\r' | awk -F': ' 'tolower($1)=="access-control-allow-origin"{print $2}')
    if [[ "$origin" == "$PANEEL_URL" ]]; then meet goed "Browser" "panel mag met Wings praten (console, hartje)"
    else meet fout "Browser" "Wings staat het panel niet toe (${origin:-geen antwoord}); zie allowed_origins in /etc/pterodactyl/config.yml"; fi
  fi
  if [[ $RN_MODUS == alles ]]; then
    if [[ "$(sql "SELECT COUNT(*) FROM database_hosts WHERE host='172.18.0.1'" 2>/dev/null || true)" == "1" ]] \
       && mysql -h 172.18.0.1 -u riantnode -p"$DBH_WW" -e 'SELECT 1' >/dev/null 2>&1; then
      meet goed "Databases" "MariaDB voor gameservers bereikbaar op 172.18.0.1"
    else
      meet fout "Databases" "databasehost ontbreekt of is niet bereikbaar"
    fi
  fi
  if [[ $RN_SSL == j ]]; then
    local tot; tot=$(openssl x509 -enddate -noout -in "/etc/letsencrypt/live/$RN_DOMEIN/fullchain.pem" 2>/dev/null | cut -d= -f2 || true)
    [[ -n "$tot" ]] && meet goed "Certificaat" "geldig tot $tot, verlengt zichzelf"
  fi
  if [[ $RN_FIVEM == j ]]; then
    if [[ -n "$(sql "SELECT e.id FROM eggs e JOIN nests n ON n.id=e.nest_id WHERE n.name='FiveM' LIMIT 1" 2>/dev/null || true)" ]]; then
      meet goed "FiveM" "egg staat in nest FiveM"
    else
      meet fout "FiveM" "egg niet gevonden"
    fi
  fi
  if [[ $RN_FIREWALL == j ]]; then
    if ufw status 2>/dev/null | grep -q 'Status: active'; then meet goed "Firewall" "ufw actief"; else meet fout "Firewall" "ufw niet actief"; fi
  fi
}

eindscherm() {
  local w=78 rij teken kleur
  echo
  printf '  %s%s%s\n' "$ERTS" "$(lijn '━' $w)" "$R"
  printf '  %s%s KLAAR %s  %s\n' "$ERTS_BG" "$INKT$B" "$R" "$(woordmerk)"
  printf '  %s%s%s\n' "$ERTS" "$(lijn '━' $w)" "$R"
  echo
  printf '  %sGemeten na de installatie%s\n' "$B" "$R"
  for rij in "${METINGEN[@]}"; do
    case "${rij%%|*}" in goed) teken="●" kleur=$GROEN ;; let) teken="▲" kleur=$GEEL ;; *) teken="■" kleur=$ROOD ;; esac
    rij=${rij#*|}
    printf '    %s%s%s %-12s %s\n' "$kleur" "$teken" "$R" "${rij%%|*}" "${rij#*|}"
  done
  echo
  if [[ $RN_MODUS != wings ]]; then
    printf '  %sInloggen%s\n' "$B" "$R"
    printf '    %s%-12s%s %s%s%s\n' "$D" "Adres" "$R" "$ERTS$B" "$PANEEL_URL" "$R"
    printf '    %s%-12s%s %s\n' "$D" "Gebruiker" "$R" "$RN_GEBRUIKER"
    if [[ $WW_GEGENEREERD == j ]]; then
      printf '    %s%-12s%s %s%s%s\n' "$D" "Wachtwoord" "$R" "$B" "$RN_WACHTWOORD" "$R"
    else
      printf '    %s%-12s%s %s\n' "$D" "Wachtwoord" "$R" "het wachtwoord dat je net koos"
    fi
    echo
  fi
  printf '  %sEn nu%s\n' "$B" "$R"
  case $RN_MODUS in
    alles)
      grijs "1. Log in en kijk bij Admin > Nodes: de node hoort een groen hartje te hebben."
      [[ $RN_FIVEM == j ]] && grijs "2. Maak een server met de egg FiveM (nest FiveM) en vul je sleutel van portal.cfx.re in."
      grijs "3. Stel e-mail in bij Admin > Settings > Mail, anders komen wachtwoordmails niet aan."
      ;;
    panel)
      grijs "1. Log in en maak bij Admin > Locations en Admin > Nodes je eerste node aan."
      grijs "2. Draai deze installer op die node met de keuze 'Alleen Wings'."
      grijs "3. Stel e-mail in bij Admin > Settings > Mail."
      ;;
    wings)
      if [[ -z "$RN_KOPPEL" ]]; then
        grijs "1. Panel > Admin > Nodes > jouw node > Configuration > Generate Token."
        grijs "2. Plak dat commando hier, dan: systemctl restart wings"
      else
        grijs "1. Kijk in je panel bij Admin > Nodes: de node hoort een groen hartje te hebben."
        grijs "2. Voeg bij Allocation de poorten toe: $RN_POORTEN"
      fi
      ;;
  esac
  echo
  grijs "Alle wachtwoorden staan in $GEGEVENS (alleen root)."
  grijs "Logboek: $LOG"
  echo
  printf '  %sGemaakt door RiantNode%s %s·%s riantnode.com %s·%s Pterodactyl is van pterodactyl.io\n' "$D" "$R" "$ERTS" "$R" "$ERTS" "$R"
  printf '  %s%s%s\n\n' "$ERTS" "$(lijn '━' $w)" "$R"
}

bewaar_gegevens() {
  umask 077
  {
    echo "RiantNode installer v$VERSIE, $(date '+%F %T')"
    echo
    [[ $RN_MODUS != wings ]] && {
      echo "Panel:        $PANEEL_URL"
      echo "Gebruiker:    $RN_GEBRUIKER ($RN_EMAIL)"
      echo "Wachtwoord:   $RN_WACHTWOORD"
      echo
      echo "Database panel (MariaDB op 127.0.0.1:3306)"
      echo "  database:   panel"
      echo "  gebruiker:  pterodactyl"
      echo "  wachtwoord: $DB_WW"
    }
    [[ $RN_MODUS == alles ]] && {
      echo
      echo "Databasehost voor gameservers (172.18.0.1:3306)"
      echo "  gebruiker:  riantnode"
      echo "  wachtwoord: $DBH_WW"
    }
  } >"$GEGEVENS"
  chmod 600 "$GEGEVENS"
  umask 022
}

# ---------------------------------------------------------------------------
#  Hoofdlijn
# ---------------------------------------------------------------------------
main() {
  case "${1:-}" in
    -h|--help|help) hulp; exit 0 ;;
  esac
  [[ "${RN_JA:-0}" == "1" ]] && NIET_INTERACTIEF=1
  kleuren
  [[ $KLEUR == 1 && $NIET_INTERACTIEF == 0 ]] && printf '\e[2J\e[H'
  logo
  echo
  grijs "Zet Pterodactyl neer zoals de officiele handleiding het beschrijft, alleen dan in een keer."
  grijs "Gratis en open source, zonder garantie. Na de installatie is de server helemaal van jou."

  kop "Controle vooraf"
  controleer_systeem
  goed "$OS_NAAM, $ARCH"
  meet_omgeving
  goed "Laatste stabiele versies: panel $PANEEL_TAG, Wings $WINGS_TAG"
  if [[ "$PUBLIEK_IP" != "$LOKAAL_IP" ]]; then goed "IP-adres: $PUBLIEK_IP (lokaal $LOKAAL_IP, achter NAT)"; else goed "IP-adres: $PUBLIEK_IP"; fi
  local ram; ram=$(ram_mb)
  if (( ram < 1800 )); then let_op "Weinig geheugen: ${ram} MB. Het panel draait, maar voor gameservers is dat krap."; else goed "Geheugen: ${ram} MB"; fi
  if [[ -d "$PANEEL" ]] && [[ -n "$(ls -A "$PANEEL" 2>/dev/null)" ]]; then
    stop_met "Er staat al een panel in $PANEEL." "Deze installer is voor een schone server en overschrijft niets."
  fi
  if [[ -x /usr/local/bin/wings ]] && [[ "${RN_MODUS:-}" != "panel" ]]; then
    stop_met "Wings staat al op deze server (/usr/local/bin/wings)." "Deze installer is voor een schone server en overschrijft niets."
  fi

  vragenronde
  samenvatting

  touch "$LOG"; chmod 600 "$LOG"
  mkdir -p "$WERKMAP"; chmod 755 "$WERKMAP"
  DB_WW=$(geheim)
  DBH_WW=$(geheim)
  bewaar_gegevens

  local -a plan=()
  plan+=("Systeem bijwerken|s_basis")
  if [[ $RN_MODUS != wings ]]; then
    plan+=("Bron voor PHP $PV|s_php_bron")
    plan+=("PHP, MariaDB, Redis, nginx|s_pakketten")
    plan+=("Composer|s_composer")
    plan+=("Panel $PANEEL_TAG downloaden|s_paneel_downloaden")
    plan+=("Database aanmaken|s_database")
    plan+=("Panel instellen|s_paneel_instellen")
    plan+=("Wachtrij en planner|s_achtergrond")
  fi
  [[ $RN_SSL == j ]] && plan+=("Certificaat ophalen|s_certificaat")
  [[ $RN_MODUS != wings ]] && plan+=("Webserver|s_webserver")
  if [[ $RN_MODUS != panel ]]; then
    plan+=("Docker|s_docker")
    plan+=("Wings $WINGS_TAG|s_wings")
  fi
  if [[ $RN_MODUS == alles ]]; then
    plan+=("Node aanmaken en koppelen|s_node_koppelen")
    plan+=("Databasehost voor servers|s_dbhost")
  fi
  [[ $RN_MODUS == wings && -n "$RN_KOPPEL" ]] && plan+=("Wings koppelen aan panel|s_wings_koppelen")
  [[ $RN_FIVEM == j ]] && plan+=("FiveM-egg importeren|s_fivem")
  [[ $RN_FIREWALL == j ]] && plan+=("Firewall|s_firewall")
  STAPPEN=${#plan[@]}

  kop "Installeren"
  echo
  [[ $RN_MODUS != wings ]] && schrijf_helper
  local p
  for p in "${plan[@]}"; do
    stap "${p%%|*}" "${p#*|}"
  done

  eindcontrole
  eindscherm
}

main "$@"
