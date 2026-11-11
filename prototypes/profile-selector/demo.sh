#!/usr/bin/env bash
# Isolated Profiles demo. Setup paths are metadata and are never sourced or executed.
set -Eeuo pipefail

SOURCE_DIR=${BASH_SOURCE[0]%/*}
[[ $SOURCE_DIR != "${BASH_SOURCE[0]}" ]] || SOURCE_DIR=.
SCRIPT_DIR=$(cd -- "$SOURCE_DIR" && pwd -P)

if [[ ! -t 0 || ! -t 1 ]]; then
  printf 'Profile demo requires an interactive terminal.\n' >&2
  exit 2
fi

die() {
  printf 'Profile demo: %s\n' "$1" >&2
  exit "${2:-1}"
}

contains_control() {
  local LC_ALL=C
  [[ $1 == *[[:cntrl:]]* ]]
}

declare -a IDS=() NAMES=() DESCRIPTIONS=() SETUP_PATHS=() AVAILABLE=()
load_registry() {
  local registry=${PROFILE_DEMO_FIXTURE_FILE:-$SCRIPT_DIR/fixtures.tsv}
  local row=0 line tabs_rest tab_count order id name description setup_path existing_id expected
  [[ -f $registry && -r $registry ]] || die 'cannot read fixtures.tsv'
  while IFS= read -r line || [[ -n $line ]]; do
    row=$((row + 1))
    if contains_control "${line//$'\t'/}"; then
      die "invalid fixtures row $row"
    fi
    if (( row == 1 )); then
      [[ $line == $'order\tid\tname\tdescription\tsetup' ]] || die 'invalid fixtures header'
      continue
    fi
    tabs_rest=$line
    tab_count=0
    while [[ $tabs_rest == *$'\t'* ]]; do
      tab_count=$((tab_count + 1))
      tabs_rest=${tabs_rest#*$'\t'}
    done
    if (( tab_count != 4 )) || [[ $line == $'\t'* || $line == *$'\t' || $line == *$'\t\t'* ]]; then
      die "invalid fixtures row $row"
    fi
    IFS=$'\t' read -r order id name description setup_path <<< "$line"
    expected=$((row - 1))
    if [[ $order != "$expected" || ! $id =~ ^[a-z0-9]+([_-][a-z0-9]+)*$ || -z $name || -z $description || $setup_path != ../../* ]]; then
      die "invalid fixtures row $row"
    fi
    for existing_id in "${IDS[@]}"; do
      [[ $existing_id != "$id" ]] || die "invalid fixtures row $row"
    done
    IDS+=("$id")
    NAMES+=("$name")
    DESCRIPTIONS+=("$description")
    SETUP_PATHS+=("$setup_path")
  done < "$registry"
  (( row > 0 )) || die 'invalid fixtures header'
}

SCENARIO=${PROFILE_DEMO_SCENARIO:-normal}
case $SCENARIO in
  normal|first-unavailable|all-unavailable|empty|error|long|return-change|filesystem) ;;
  *) die 'Unknown demo scenario' ;;
esac

DELAY=${PROFILE_DEMO_DELAY:-0.7}
[[ $DELAY =~ ^(0|[1-9][0-9]?)(\.[0-9]{1,3})?$ ]] || die 'PROFILE_DEMO_DELAY must be between 0 and 30 seconds'
DELAY_WHOLE=${DELAY%%.*}
if [[ $DELAY == *.* ]]; then DELAY_FRACTION=${DELAY#*.}; else DELAY_FRACTION=000; fi
while ((${#DELAY_FRACTION} < 3)); do DELAY_FRACTION+=0; done
DELAY_MS=$((10#$DELAY_WHOLE * 1000 + 10#$DELAY_FRACTION))
(( DELAY_MS <= 30000 )) || die 'PROFILE_DEMO_DELAY must be between 0 and 30 seconds'
DELAY_US=$((DELAY_MS * 1000))

load_registry
if [[ $SCENARIO == empty ]]; then
  IDS=() NAMES=() DESCRIPTIONS=() SETUP_PATHS=()
elif [[ $SCENARIO == long ]]; then
  for ((fixture = 1; fixture <= 24; fixture++)); do
    printf -v suffix '%02d' "$fixture"
    IDS+=("fixture-$suffix")
    NAMES+=("fixture-$suffix")
    DESCRIPTIONS+=("Fictitious scroll fixture; not an installable environment")
    SETUP_PATHS+=("not-installable/fixture-$suffix")
  done
fi

TRUECOLOR=0
case ${COLORTERM:-} in truecolor|24bit) TRUECOLOR=1 ;; esac
declare -A RGB=([bg]='20;23;28' [text]='241;243;245' [secondary]='146;154;166' \
  [border]='52;58;67' [focus]='41;47;57' [accent]='146;180;231' [error]='229;139;139')
declare -A INDEX=([bg]=233 [text]=255 [secondary]=245 [border]=238 [focus]=236 [accent]=110 [error]=217)
color() {
  local name=$1 layer=38
  [[ ${2:-0} == 1 ]] && layer=48
  if (( TRUECOLOR )); then
    printf '\033[%s;2;%sm' "$layer" "${RGB[$name]}"
  else
    printf '\033[%s;5;%sm' "$layer" "${INDEX[$name]}"
  fi
}

readonly RESET=$'\033[0m'
readonly CHECKING_TEXT='Checking profile availability...'
readonly NORMAL_FOOTER='↑↓ Navigate · Enter Select · Esc Exit'
readonly ERROR_DETAIL='Simulated EACCES while reading the declared setup reference; demo fixtures only.'
readonly SPINNER='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
readonly BG_MAIN="$(color bg 1)"
readonly FG_BORDER="$(color border)"

WRAPPED=()
wrap_text() {
  local rest=$1 width=$2 chunk part cut
  WRAPPED=()
  (( width > 0 )) || width=1
  if [[ -z $rest ]]; then
    WRAPPED+=("")
    return
  fi
  while ((${#rest} > width)); do
    chunk=${rest:0:width}
    if [[ $chunk == *' '* ]]; then
      part=${chunk% *}
      if [[ -n $part ]]; then
        cut=${#part}
      else
        cut=$width
        part=${rest:0:cut}
      fi
    else
      cut=$width
      part=${rest:0:cut}
    fi
    WRAPPED+=("$part")
    rest=${rest:cut}
    while [[ $rest == ' '* ]]; do rest=${rest:1}; done
  done
  WRAPPED+=("$rest")
}

TRUNCATED=''
truncate_text() {
  local value=$1 width=$2
  if ((${#value} > width)); then
    if (( width > 0 )); then TRUNCATED="${value:0:width-1}…"; else TRUNCATED=''; fi
  else
    TRUNCATED=$value
  fi
}

FRAME=''
LEFT_PAD=''
append_line() {
  local value=${1-} foreground=${2:-text} bold=${3:-0}
  FRAME+="$BG_MAIN$LEFT_PAD$(color "$foreground")"
  if [[ $bold == 1 ]]; then FRAME+=$'\033[1m'; fi
  FRAME+="$value"
  if [[ $bold == 1 ]]; then FRAME+=$'\033[22m'; fi
  FRAME+="$RESET"$'\n'
}

panel_line() {
  local value=${1-} foreground=${2:-secondary} row_bg=${3:-bg} padded padding
  # Bash printf field widths count bytes, while UTF-8 fixture layout uses characters.
  printf -v padding '%*s' "$((INNER - ${#value}))" ''
  padded=$value$padding
  FRAME+="$BG_MAIN$LEFT_PAD$FG_BORDER│ $(color "$row_bg" 1)$(color "$foreground") $padded $(color bg 1)$FG_BORDER │"$'\n'
}

panel_border() {
  local top=$1 label=${2-} edge end body fill count
  if [[ $top == 1 ]]; then edge='┌'; end='┐'; else edge='└'; end='┘'; fi
  if [[ -n $label ]]; then body="─ $label "; else body=''; fi
  count=$((WIDTH - 2 - ${#body}))
  (( count >= 0 )) || count=0
  printf -v fill '%*s' "$count" ''
  fill=${fill// /─}
  FRAME+="$BG_MAIN$LEFT_PAD$FG_BORDER$edge$body$fill$end$RESET"$'\n'
}

NOW_US=0
clock_now() { NOW_US=${EPOCHREALTIME/./}; }

FOCUS=-1
OFFSET=0
CAPACITY=1
RETURNED_ID=''
RETURNING=0
MOCK=0
CHECKING=1
ERROR_STATE=0
SPINNER_INDEX=0
CHECK_STARTED_US=0
LAST_SPINNER_US=0
start_check() {
  CHECKING=1
  SPINNER_INDEX=0
  clock_now
  CHECK_STARTED_US=$NOW_US
  LAST_SPINNER_US=$NOW_US
}

first_available() {
  local index
  FOCUS=-1
  for index in "${!IDS[@]}"; do
    if [[ ${AVAILABLE[index]:-0} == 1 ]]; then
      FOCUS=$index
      return
    fi
  done
}

ensure_visible() {
  local count=${#IDS[@]} max_offset
  if (( FOCUS >= 0 )); then
    if (( FOCUS < OFFSET )); then OFFSET=$FOCUS
    elif (( FOCUS >= OFFSET + CAPACITY )); then OFFSET=$((FOCUS - CAPACITY + 1)); fi
  fi
  max_offset=$((count - CAPACITY))
  (( max_offset >= 0 )) || max_offset=0
  if (( OFFSET > max_offset )); then OFFSET=$max_offset; fi
  (( OFFSET >= 0 )) || OFFSET=0
}

complete_check() {
  local index available setup_root=${PROFILE_DEMO_SETUP_ROOT:-$SCRIPT_DIR}
  CHECKING=0
  if [[ $SCENARIO == error ]]; then ERROR_STATE=1; return; fi
  AVAILABLE=()
  for index in "${!IDS[@]}"; do
    available=1
    case $SCENARIO in
      first-unavailable) (( index != 0 )) || available=0 ;;
      all-unavailable) available=0 ;;
      return-change)
        if (( RETURNING )) && [[ ${IDS[index]} == "$RETURNED_ID" ]]; then available=0; fi
        ;;
      filesystem)
        if [[ ! -f $setup_root/${SETUP_PATHS[index]} || ! -x $setup_root/${SETUP_PATHS[index]} ]]; then
          available=0
        fi
        ;;
    esac
    AVAILABLE[index]=$available
  done
  if (( FOCUS < 0 )) || [[ ${AVAILABLE[FOCUS]:-0} != 1 ]]; then
    first_available
    OFFSET=0
  fi
  ensure_visible
}

get_size() {
  local size extra
  size=$(stty size <&0) || die 'cannot read terminal size'
  read -r TERM_ROWS TERM_COLUMNS extra <<< "$size"
  [[ ${TERM_ROWS:-} =~ ^[0-9]+$ && ${TERM_COLUMNS:-} =~ ^[0-9]+$ && -z ${extra:-} ]] || die 'cannot read terminal size'
}

render_resize_notice() {
  local message=${1:-'Resize terminal. Esc Exit'} index
  FRAME="$BG_MAIN"$'\033[H\033[2J'
  LEFT_PAD=''
  if (( TERM_ROWS < 3 )); then WRAPPED=('Esc')
  else wrap_text "$message" "$((TERM_COLUMNS - 1))"; fi
  for ((index = 0; index < ${#WRAPPED[@]} && index < TERM_ROWS; index++)); do
    append_line "${WRAPPED[index]}" secondary
  done
}

render() {
  local index name description row_bg foreground end_index
  local -a HEADER_LINES=() HEADER_FG=() HEADER_BOLD=() STATUS_LINES=() STATUS_FG=()
  local -a FOOTER_LINES=() CONTENT_LINES=() CONTENT_FG=()
  local footer footer_reserve status_reserve base_budget content_length panel_padding

  WIDTH=$((TERM_COLUMNS - 2))
  (( WIDTH > 64 )) && WIDTH=64
  if (( WIDTH < 24 || TERM_ROWS < 12 )); then
    render_resize_notice
    return
  fi
  LEFT=$(((TERM_COLUMNS - WIDTH) / 2))
  printf -v LEFT_PAD '%*s' "$LEFT" ''
  INNER=$((WIDTH - 6))

  HEADER_LINES=('' 'dotfiles' 'Select profile')
  HEADER_FG=(secondary secondary text)
  HEADER_BOLD=(0 0 1)
  wrap_text 'Choose the environment to configure' "$WIDTH"
  for name in "${WRAPPED[@]}"; do
    HEADER_LINES+=("$name")
    HEADER_FG+=(secondary)
    HEADER_BOLD+=(0)
  done
  HEADER_LINES+=('')
  HEADER_FG+=(secondary)
  HEADER_BOLD+=(0)

  if (( MOCK )); then footer='Esc Back to Profiles'
  elif (( CHECKING || ERROR_STATE )) || (( FOCUS < 0 )); then footer='Esc Exit'
  else footer=$NORMAL_FOOTER
  fi
  wrap_text "$footer" "$WIDTH"
  FOOTER_LINES=("${WRAPPED[@]}")

  if (( CHECKING && RETURNING )); then
    wrap_text "${SPINNER:SPINNER_INDEX:1} $CHECKING_TEXT" "$WIDTH"
    STATUS_LINES=("${WRAPPED[@]}")
    STATUS_FG=()
    for name in "${STATUS_LINES[@]}"; do STATUS_FG+=(accent); done
  elif (( !CHECKING && !ERROR_STATE && !MOCK && ${#IDS[@]} > 0 )); then
    local any_available=0
    for index in "${!IDS[@]}"; do
      [[ ${AVAILABLE[index]:-0} == 1 ]] && any_available=1
    done
    if (( !any_available )); then
      wrap_text 'No compatible profiles available.' "$WIDTH"
      STATUS_LINES=("${WRAPPED[@]}")
      STATUS_FG=()
      for name in "${STATUS_LINES[@]}"; do STATUS_FG+=(secondary); done
    fi
  fi
  status_reserve=${#STATUS_LINES[@]}
  wrap_text "⠋ $CHECKING_TEXT" "$WIDTH"
  ((${#WRAPPED[@]} <= status_reserve)) || status_reserve=${#WRAPPED[@]}
  footer_reserve=${#FOOTER_LINES[@]}
  wrap_text "$NORMAL_FOOTER" "$WIDTH"
  ((${#WRAPPED[@]} <= footer_reserve)) || footer_reserve=${#WRAPPED[@]}

  base_budget=$((TERM_ROWS - ${#HEADER_LINES[@]} - 2 - 1 - status_reserve - footer_reserve - 1))
  if (( base_budget < 2 )); then
    render_resize_notice
    return
  fi
  panel_padding=0
  if (( base_budget >= 6 )); then panel_padding=1; fi
  CAPACITY=$(((base_budget - panel_padding * 2) / 2))
  (( CAPACITY > 0 )) || CAPACITY=1
  ensure_visible

  if (( ERROR_STATE )); then
    wrap_text 'Availability check failed.' "$INNER"
    for name in "${WRAPPED[@]}"; do CONTENT_LINES+=("$name"); CONTENT_FG+=(error); done
    wrap_text "$ERROR_DETAIL" "$INNER"
    for name in "${WRAPPED[@]}"; do CONTENT_LINES+=("$name"); CONTENT_FG+=(error); done
  elif (( CHECKING && !RETURNING )); then
    wrap_text "${SPINNER:SPINNER_INDEX:1} $CHECKING_TEXT" "$INNER"
    for name in "${WRAPPED[@]}"; do CONTENT_LINES+=("$name"); CONTENT_FG+=(accent); done
  elif (( MOCK )); then
    wrap_text 'SIMULATION ONLY — Components not implemented.' "$INNER"
    for name in "${WRAPPED[@]}"; do CONTENT_LINES+=("$name"); CONTENT_FG+=(secondary); done
    wrap_text "Selected fixture: ${IDS[FOCUS]}" "$INNER"
    for name in "${WRAPPED[@]}"; do CONTENT_LINES+=("$name"); CONTENT_FG+=(secondary); done
    wrap_text 'No setup script is invoked.' "$INNER"
    for name in "${WRAPPED[@]}"; do CONTENT_LINES+=("$name"); CONTENT_FG+=(secondary); done
  elif ((${#IDS[@]} == 0)); then
    wrap_text 'No profiles available.' "$INNER"
    for name in "${WRAPPED[@]}"; do CONTENT_LINES+=("$name"); CONTENT_FG+=(secondary); done
  fi

  content_length=${#CONTENT_LINES[@]}
  if (( content_length > base_budget - panel_padding * 2 )); then
    render_resize_notice 'Resize terminal to read the complete message. Esc Exit'
    return
  fi

  FRAME="$BG_MAIN"$'\033[H\033[2J'
  for ((index = 0; index < ${#HEADER_LINES[@]}; index++)); do
    append_line "${HEADER_LINES[index]}" "${HEADER_FG[index]}" "${HEADER_BOLD[index]}"
  done
  if (( content_length > 0 )); then
    panel_border 1
    for ((index = 0; index < panel_padding; index++)); do panel_line; done
    for ((index = 0; index < content_length; index++)); do
      panel_line "${CONTENT_LINES[index]}" "${CONTENT_FG[index]}"
    done
    for ((index = 0; index < panel_padding; index++)); do panel_line; done
    panel_border 0
  else
    local top_label='' bottom_label=''
    (( OFFSET > 0 )) && top_label='↑ More'
    end_index=$((OFFSET + CAPACITY))
    (( end_index > ${#IDS[@]} )) && end_index=${#IDS[@]}
    (( end_index < ${#IDS[@]} )) && bottom_label='↓ More'
    panel_border 1 "$top_label"
    for ((index = 0; index < panel_padding; index++)); do panel_line; done
    for ((index = OFFSET; index < end_index; index++)); do
      if [[ ${AVAILABLE[index]:-0} == 1 ]]; then
        foreground=text
        name=${NAMES[index]}
        [[ $index == "$FOCUS" ]] && row_bg=focus || row_bg=bg
      else
        foreground=secondary
        name="${NAMES[index]} · Unavailable"
        row_bg=bg
      fi
      truncate_text "$name" "$INNER"
      panel_line "$TRUNCATED" "$foreground" "$row_bg"
      description=${DESCRIPTIONS[index]}
      truncate_text "$description" "$INNER"
      panel_line "$TRUNCATED" secondary "$row_bg"
    done
    for ((index = 0; index < panel_padding; index++)); do panel_line; done
    panel_border 0 "$bottom_label"
  fi

  append_line '' secondary
  for ((index = 0; index < status_reserve; index++)); do
    append_line "${STATUS_LINES[index]-}" "${STATUS_FG[index]:-secondary}"
  done
  for name in "${FOOTER_LINES[@]}"; do append_line "$name" secondary; done
}

read_key() {
  local first second third
  KEY=''
  if ! IFS= read -r -s -n 1 -t 0.05 first; then return 0; fi
  if [[ $first == $'\033' ]]; then
    if IFS= read -r -s -n 1 -t 0.04 second; then
      if [[ $second == '[' || $second == O ]]; then
        if IFS= read -r -s -n 1 -t 0.04 third; then
          case $third in A) KEY=up ;; B) KEY=down ;; esac
        fi
      else
        KEY=escape
      fi
    else
      KEY=escape
    fi
  elif [[ -z $first || $first == $'\n' || $first == $'\r' ]]; then
    KEY=enter
  fi
}

SAVED_STTY=''
TERMINAL_ACTIVE=0
CLEANED=0
cleanup() {
  local status=$?
  if (( CLEANED )); then return "$status"; fi
  CLEANED=1
  trap - EXIT
  if (( TERMINAL_ACTIVE )); then
    stty "$SAVED_STTY" <&0 2>/dev/null || true
    printf '%s' $'\033[0m\033[?25h\033[?1049l'
  fi
  return "$status"
}
trap cleanup EXIT
RUNNING=1
trap 'RUNNING=0' INT TERM HUP
RESIZED=1
trap 'RESIZED=1' WINCH
SAVED_STTY=$(stty -g <&0) || die 'cannot read terminal settings'
TERMINAL_ACTIVE=1
stty -echo -icanon <&0 || die 'cannot configure terminal'
printf '%s' $'\033[?1049h\033[?25l'

AVAILABLE=()
start_check
get_size
SIZE_CHECK_US=$NOW_US
LAST_FRAME=''
while (( RUNNING )); do
  clock_now
  if (( CHECKING )); then
    if (( NOW_US - CHECK_STARTED_US >= DELAY_US )); then complete_check; fi
    if (( CHECKING && NOW_US - LAST_SPINNER_US >= 100000 )); then
      SPINNER_INDEX=$(((SPINNER_INDEX + 1) % ${#SPINNER}))
      LAST_SPINNER_US=$NOW_US
    fi
  fi
  if (( RESIZED || NOW_US - SIZE_CHECK_US >= 100000 )); then
    get_size
    SIZE_CHECK_US=$NOW_US
    RESIZED=0
  fi
  if [[ ${PROFILE_DEMO_TEST_FAULT:-} == render ]]; then
    printf 'Profile demo: Simulated render exception\n' >&2
    exit 1
  fi
  render
  if [[ $FRAME != "$LAST_FRAME" ]]; then
    printf '%s' "$FRAME"
    LAST_FRAME=$FRAME
  fi
  read_key
  if [[ $KEY == escape ]]; then
    if (( MOCK )); then
      RETURNED_ID=${IDS[FOCUS]}
      MOCK=0
      RETURNING=1
      start_check
    else
      RUNNING=0
    fi
  elif (( !MOCK && !CHECKING && !ERROR_STATE && FOCUS >= 0 )); then
    case $KEY in
      up|down)
        step=-1
        [[ $KEY == down ]] && step=1
        candidate=$((FOCUS + step))
        while (( candidate >= 0 && candidate < ${#IDS[@]} )); do
          if [[ ${AVAILABLE[candidate]:-0} == 1 ]]; then FOCUS=$candidate; break; fi
          candidate=$((candidate + step))
        done
        ensure_visible
        ;;
      enter) MOCK=1; RETURNING=0 ;;
    esac
  fi
done
exit 0
