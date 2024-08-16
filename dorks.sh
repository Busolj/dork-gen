#!/bin/bash

# Default variable values
verbose_mode=false
output_file=""

declare -A dorks

dorks=(
  ["sensitive files"]="ext:txt OR ext:log OR ext:cfg"
  ["Database Configurations"]="ext:sql OR ext:db OR ext:sqlitedb"
  ["Test Environments"]="inurl:test OR inurl:env OR inurl:dev OR inurl:staging OR inurl:sandbox OR inurl:debug OR inurl:temp OR inurl:internal OR inurl:demo"
  ["Backup Infos"]="ext:bak OR ext:old OR ext:backup"
  ["Passwords file exposed"]="inurl:passwd OR inurl:shadow OR inurl:htpasswd"
  ["Admin/Login Panes"]="inurl:login OR inurl:admin OR inurl:dashboard OR inurl:portal"
  ["Source Code"]="ext:php OR ext:js OR ext:asp"
  ["Documents"]="ext:doc OR ext:docx OR ext:pdf OR ext:xls OR ext:xlsx"
  ["Cameras/IOT Devices Exposed"]="inurl:viewerframe?mode= OR inurl:axis-cgi/jpg OR inurl:view/index.shtml"
  ["Open Directories"]="intitle:index.of"
  ["API Logs"]="inurl:api inurl:log"
  ["Errors with sensitive information"]='intext:"Fatal error" OR intext:"syntax error"'
)

usage() {
  echo "Usage: $0 [OPTIONS]"
  echo "Options:"
  echo " -h, --help      Display this help message"
  echo " -f, --file      FILE Specify an output file"
  echo " -s, --single    Generate each dork for each domain"
  echo " -a, --all      Generate each dork for all domains at once"
}

has_argument() {
  [[ ("$1" == *=* && -n ${1#*=}) || (! -z "$2" && "$2" != -*) ]]
}

extract_argument() {
  echo "${2:-${1#*=}}"
}

function generate_dork_for_domain {
  local domain_list=$(cat $DOMAINS_FILE)

  for domain in $domain_list; do
    for dork in "${!dorks[@]}"; do
      echo "site: $domain ${dorks[$dork]}"
    done
  done
}

function fetch_domains {
  local domain_list=$(cat $DOMAINS_FILE)

  local COUNTER=0
  local TOTAL_DOMAINS=$(wc -l <$DOMAINS_FILE)

  for domain in $domain_list; do
    COUNTER=$((COUNTER + 1))
    DOMAINS_DORK="${DOMAINS_DORK}site:$domain"

    if [[ "$COUNTER" -lt "$TOTAL_DOMAINS" ]]; then
      DOMAINS_DORK="${DOMAINS_DORK} OR "
    fi
  done

  echo "$DOMAINS_DORK"
}

function all_domains {
  for dork in "${dorks[@]}"; do
    echo "$DOMAINS_DORK" $dork
  done
}

handle_options() {
  while [ $# -gt 0 ]; do
    case $1 in
    -h | --help)
      usage
      exit 0
      ;;
    -f | --file*)
      if ! has_argument $@; then
        echo "File not specified." >&2
        usage
        exit 1
      fi

      DOMAINS_FILE=$(extract_argument $@)

      shift
      ;;
    -s | --single)
      generate_dork_for_domain $DOMAINS_FILE
      exit 1
      ;;
    -a | --all)
      DOMAIN_LIST_DORK=$(fetch_domains $DOMAINS_FILE)
      for dork in "${dorks[@]}"; do
        echo "($DOMAIN_LIST_DORK) ($dork)"
      done

      exit 1
      ;;
    *)
      echo "Invalid option: $1" >&2
      usage
      exit 1
      ;;
    esac
    shift
  done
}

handle_options "$@"
