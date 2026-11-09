#!/bin/bash
# ==========================================================
#  RT DEV KERNEL DRIVER LOADER
#  Author   : MD MAWA ISLAM
#  Telegram : @mawa4k
#  GitHub   : https://github.com/Mawa4k/Driver
# ==========================================================

AUTHOR="MD MAWA ISLAM"
TG="@mawa4k"
VERSION="v3.1"
LINK="https://github.com/Mawa4k/Driver/raw/main/Kernel%20Driver.zip"

H=/data/data/com.termux/files/home
T=/data/local/tmp
ZIP="$H/KernelDriver.zip"
OUT="$H/KernelDriver"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCALZIP="$SCRIPT_DIR/Kernel Driver.zip"

# ---------- COLORS ----------
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'
B='\033[1;34m'; C='\033[1;36m'; W='\033[1;37m'
M='\033[1;35m'; DG='\033[2;32m'; N='\033[0m'

# ---------- HELPERS ----------
ok()  { echo -e "${G}[ OK ]${N} $1"; }
inf() { echo -e "${C}[ .. ]${N} $1"; }
wrn() { echo -e "${Y}[ !! ]${N} $1"; }
die() { echo -e "${R}[FAIL]${N} $1"; exit 1; }

typeout() {
  local s="$1" i
  for ((i=0; i<${#s}; i++)); do printf '%s' "${s:$i:1}"; sleep 0.01; done
  echo
}

spinner() {
  local pid=$1 msg=$2 sp='|/-\' i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r${C}[ %s ]${N} %s" "${sp:i++%4:1}" "$msg"
    sleep 0.1
  done
  printf "\r\033[K"
}

hr()  { echo -e "${DG}  ──────────────────────────────────────────────${N}"; }
hrg() { echo -e "${G}  ══════════════════════════════════════════════${N}"; }

banner() {
  clear
  echo -e "${G}"
  cat <<'BANNER'
  __  __    _    __        __    _
 |  \/  |  / \   \ \      / /   / \
 | |\/| | / _ \   \ \ /\ / /   / _ \
 | |  | |/ ___ \   \ V  V /   / ___ \
 |_|  |_/_/   \_\   \_/\_/   /_/   \_\
BANNER
  echo -e "${N}"
  hrg
  echo -e "   ${W}RT DEV KERNEL DRIVER LOADER ${Y}${VERSION}${N}"
  echo -e "   ${C}Author   ${W}: ${G}${AUTHOR}${N}"
  echo -e "   ${C}Telegram ${W}: ${G}${TG}${N}"
  hrg
  echo
}

# ---------- DEVICE INFO ----------
getinfo() {
  KFULL=$(uname -r)
  KVER=$(echo "$KFULL" | grep -oE '^[0-9]+\.[0-9]+(\.[0-9]+)?')
  KSER=$(echo "$KVER" | cut -d. -f1-2)
  KPATCH=$(echo "$KVER" | cut -d. -f3)
  [ -z "$KPATCH" ] && KPATCH=0
  ARCH=$(uname -m)
  ANDROID=$(getprop ro.build.version.release 2>/dev/null)
  MODEL=$(getprop ro.product.model 2>/dev/null)
  if [ "$(id -u)" -eq 0 ] || su -c id >/dev/null 2>&1; then
    ROOT="${G}GRANTED${N}"; ROOTOK=1
  else
    ROOT="${R}DENIED${N}"; ROOTOK=0
  fi
}

sysinfo() {
  echo -e "${DG}  [ DEVICE INFO ]${N}"
  hr
  echo -e "   ${C}Model    ${W}: ${W}${MODEL:-unknown}${N}"
  echo -e "   ${C}Android  ${W}: ${W}${ANDROID:-unknown}${N}"
  echo -e "   ${C}Arch     ${W}: ${W}${ARCH}${N}"
  echo -e "   ${C}Kernel   ${W}: ${Y}${KFULL}${N}"
  echo -e "   ${C}Series   ${W}: ${M}${KSER}.x${N}"
  echo -e "   ${C}Root     ${W}: ${ROOT}"
  hr
  echo
}

# ---------- BOOT SEQUENCE ----------
boot() {
  banner
  typeout "$(echo -e "${G}[+] Initializing RT Dev Loader ${VERSION}...${N}")"
  sleep 0.2
  getinfo
  inf "Scanning device ............ ${W}${MODEL:-unknown}${N}"; sleep 0.15
  inf "Detecting kernel .......... ${W}${KFULL}${N}"; sleep 0.15
  if [ "$ROOTOK" = "1" ]; then ok "Root access ............ ${G}GRANTED${N}"
  else wrn "Root access ............ ${R}DENIED${N}"; fi
  sleep 0.2
}

# ---------- ZIP SETUP (first time only) ----------
find_root() {
  [ -d "$OUT" ] && find "$OUT" -type f -name '*.sh' 2>/dev/null | grep -v __MACOSX | head -n 1
}

setup() {
  [ -n "$(find_root)" ] && { ok "Drivers ready (cached)"; sleep 0.3; return 0; }

  command -v unzip >/dev/null || { inf "Installing unzip..."; pkg install unzip -y >/dev/null 2>&1; }

  rm -rf "$OUT"
  if [ -f "$LOCALZIP" ]; then
    ok "Local zip found (git clone)"
    cp -f "$LOCALZIP" "$ZIP"
  else
    command -v curl >/dev/null || { inf "Installing curl..."; pkg install curl -y >/dev/null 2>&1; }
    rm -f "$ZIP.tmp"
    curl -L --fail -s -o "$ZIP.tmp" "$LINK" &
    spinner $! "Downloading drivers (first time only)..."
    wait $!
    [ -s "$ZIP.tmp" ] || { rm -f "$ZIP.tmp"; die "Download failed. Internet চেক করো।"; }
    unzip -tq "$ZIP.tmp" >/dev/null 2>&1 || { rm -f "$ZIP.tmp"; die "ফাইলটা সঠিক zip না।"; }
    mv "$ZIP.tmp" "$ZIP"
    ok "Download complete"
  fi

  mkdir -p "$OUT"
  unzip -oq "$ZIP" -d "$OUT" &
  spinner $! "Extracting..."
  wait $!
  [ -n "$(find_root)" ] || { rm -rf "$OUT"; die "Zip এর ভেতরে কোনো .sh driver নেই।"; }
  ok "Extract complete"
  sleep 0.4
}

# ---------- MATCH LOGIC ----------
verof() { echo "$1" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1; }

# result in MATCHLVL: 2 exact, 1 same series, 0 none
classify() {
  local st sser
  st=$(verof "$1"); MATCHLVL=0
  [ -z "$st" ] && return
  sser=$(echo "$st" | cut -d. -f1-2)
  if [ "$KVER" = "$st" ] || [[ "$KVER" == "$st".* ]]; then MATCHLVL=2
  elif [ "$sser" = "$KSER" ]; then MATCHLVL=1
  fi
}

# closest patch inside same series → BESTREL
find_best() {
  BESTREL=""; local r st p diff bestdiff=999999
  for r in "$@"; do
    classify "$r"
    [ "$MATCHLVL" = "2" ] && { BESTREL="$r"; return; }
    if [ "$MATCHLVL" = "1" ]; then
      st=$(verof "$r"); p=$(echo "$st" | cut -d. -f3); [ -z "$p" ] && p=0
      diff=$(( p > KPATCH ? p - KPATCH : KPATCH - p ))
      if [ "$diff" -lt "$bestdiff" ]; then bestdiff=$diff; BESTREL="$r"; fi
    fi
  done
}

legend() {
  echo -e "  ${G}★ EXACT${N} = kernel মিলেছে   ${Y}★ BEST${N} = সবচেয়ে কাছের"
  echo -e "  ${C}● RECOMMENDED${N} = একই series (${KSER}.x)"
  echo
}

# ---------- FIND TOP-LEVEL PACKS ----------
list_scripts() {
  local p="$1"
  if [ "$p" = "$BASE" ]; then
    find "$p" -maxdepth 1 -type f -name '*.sh' ! -name 'kernel-info.sh' -printf '%P\n'
  else
    find "$p" -type f -name '*.sh' ! -name 'kernel-info.sh' -printf '%P\n'
  fi
}
pack_name() { [ "$1" = "$BASE" ] && echo "Main Drivers" || basename "$1"; }

get_packs() {
  local b="$OUT" n d p
  while :; do
    n=$(find "$b" -mindepth 1 -maxdepth 1 ! -name '__MACOSX' | wc -l)
    d=$(find "$b" -mindepth 1 -maxdepth 1 -type d ! -name '__MACOSX' | wc -l)
    [ "$n" -eq 1 ] && [ "$d" -eq 1 ] || break
    b=$(find "$b" -mindepth 1 -maxdepth 1 -type d ! -name '__MACOSX')
  done
  BASE="$b"; PACKS=()
  [ -n "$(list_scripts "$BASE" | head -n 1)" ] && PACKS+=("$BASE")
  while IFS= read -r p; do
    [ -n "$(list_scripts "$p" | head -n 1)" ] && PACKS+=("$p")
  done < <(find "$b" -mindepth 1 -maxdepth 1 -type d ! -name '__MACOSX' | sort -V)
}

# ---------- MENUS ----------
choose_folder() {
  while true; do
    banner; sysinfo
    get_packs
    [ ${#PACKS[@]} -eq 0 ] && die "কোনো driver folder পাওয়া যায়নি"

    echo -e "${G}  [ SELECT DRIVER FOLDER: ${#PACKS[@]} ]${N}"
    hr
    local i=0 d cnt hit f
    for d in "${PACKS[@]}"; do
      i=$((i+1))
      cnt=0; hit=""
      while IFS= read -r f; do
        cnt=$((cnt+1))
        if [ -z "$hit" ]; then
          classify "$f"
          [ "$MATCHLVL" -ge 1 ] && hit="  ${Y}★ match${N}"
        fi
      done < <(list_scripts "$d")
      echo -e "  ${C}[$i]${W} $(pack_name "$d") ${DG}(${cnt} drivers)${N}${hit}"
    done
    hr
    echo -e "  ${Y}[u]${W} Update   ${Y}[c]${W} Clear cache   ${Y}[t]${W} Telegram   ${Y}[0]${W} Exit"
    echo
    echo -ne "${G}  mawa4k@rtdev${W}:${B}folders${W}# ${N}"
    read -r n
    case "$n" in
      0) echo -e "\n${G}  Bye! Follow ${TG}${N}\n"; exit 0 ;;
      u|U) rm -rf "$OUT" "$ZIP"; wrn "Cache মুছে নতুন করে download হচ্ছে..."; setup ;;
      c|C) rm -rf "$OUT" "$ZIP"; ok "Cache cleared. আবার চালালে নতুন করে download হবে।"; exit 0 ;;
      t|T) command -v termux-open-url >/dev/null && termux-open-url "https://t.me/mawa4k" ;;
      ''|*[!0-9]*) wrn "ভুল ইনপুট!"; sleep 1 ;;
      *)
        if [ "$n" -ge 1 ] && [ "$n" -le ${#PACKS[@]} ]; then
          PACK="${PACKS[$((n-1))]}"
          choose_driver && return 0
        else
          wrn "ভুল নম্বর!"; sleep 1
        fi ;;
    esac
  done
}

choose_driver() {
  while true; do
    banner; sysinfo
    mapfile -t FILES < <(list_scripts "$PACK" | sort -V)
    find_best "${FILES[@]}"

    echo -e "${G}  [ $(pack_name "$PACK") — ${#FILES[@]} drivers ]${N}"
    hr
    local i=0 r tag
    for r in "${FILES[@]}"; do
      i=$((i+1))
      classify "$r"; tag=""
      if [ "$MATCHLVL" = "2" ]; then tag="${G}★ EXACT${N}"
      elif [ "$r" = "$BESTREL" ]; then tag="${Y}★ BEST${N}"
      elif [ "$MATCHLVL" = "1" ]; then tag="${C}● RECOMMENDED${N}"
      fi
      echo -e "  ${C}[$i]${W} ${r%.sh}${N} ${tag}"
    done
    hr
    legend
    echo -e "  ${Y}[b]${W} Back   ${Y}[0]${W} Exit"
    echo
    echo -ne "${G}  mawa4k@rtdev${W}:${B}drivers${W}# ${N}"
    read -r n
    case "$n" in
      0) echo -e "\n${G}  Bye! Follow ${TG}${N}\n"; exit 0 ;;
      b|B) return 1 ;;
      ''|*[!0-9]*) wrn "ভুল ইনপুট!"; sleep 1 ;;
      *)
        if [ "$n" -ge 1 ] && [ "$n" -le ${#FILES[@]} ]; then
          run_driver "${FILES[$((n-1))]}"; return 0
        else
          wrn "ভুল নম্বর!"; sleep 1
        fi ;;
    esac
  done
}

run_driver() {
  local REL="$1" F SRC
  F=$(basename "$REL"); SRC="$PACK/$REL"
  echo
  inf "Selected  : ${W}${REL%.sh}${N}"
  inf "Copying   : ${W}$T/$F${N}"
  su -c "cp '$SRC' '$T/$F' && chmod 755 '$T/$F'" || die "Copy failed! Root access চেক করো।"
  ok "Copied & permission set"
  inf "Executing..."
  hr
  su -c "sh '$T/$F'"
  hr
  ok "Done!  ${AUTHOR} (${TG})"
  echo
}

# ---------- START ----------
boot
setup
choose_folder
