#!/bin/sh
# Get aggregated IPv4 preffixes list for a country using RIPE IP delegation data
set -e
shopt -s extglob

countries="RU ES DE"
families="ipv4 ipv6"
table_url="https://ftp.ripe.net/ripe/stats/delegated-ripencc-latest"
checksum_url="https://ftp.ripe.net/ripe/stats/delegated-ripencc-latest.md5"

state_dir="/var/lib/country-prefixes"
checksum="$state_dir/delegated-ripencc-latest.md5"
checksum_prev="$state_dir/delegated-ripencc-prev.md5"
table="$state_dir/delegated-ripencc-latest"

mkdir -p "$state_dir"

error(){
  echo "E: $@" >&2
}

ripe_process_ipv4(){
  local country="$1"
  local table="$2"
  local state_dir="$3"
  awk -F '|' -v country="$country" -v family="ipv4" \
        '$2==country && $3==family {split($4,a,"."); u32=((a[1]*256+a[2])*256+a[3])*256+a[4]; printf("%s %08x\n",$4,u32+$5-1) }' "$table"|
    awk '{gsub(/../, "0x& ", $2); print $1,$2}'|
    awk '{print $1"-"strtonum($2)"."strtonum($3)"."strtonum($4)"."strtonum($5)}'|
    xargs -n1 ipcalc --no-decorate -d |
    sort -u > "$state_dir/ipv4-$country.delegated"
  cat "$state_dir/ipv4-$country.delegated"|aggregate|sort > "$state_dir/ipv4-$country.aggregated"
  #comm -12 "$state_dir/ipv4-$country.aggregated" "$state_dir/all-advertised" > "$state_dir/ipv4-$country.advertised"
}

ripe_process_ipv6(){
  local country="$1"
  local table="$2"
  local state_dir="$3"
  awk -F '|' -v country="$country" -v family="ipv6" \
        '$2==country && $3==family {print $4"/"$5}' "$table"|
    sort -u > "$state_dir/ipv6-$country.delegated"
  #cat "$state_dir/ipv6-$country.delegated"|aggregate|sort > "$state_dir/ipv6-$country.aggregated"
  #comm -12 "$state_dir/ipv4-$country" "$state_dir/all-advertised" > "$state_dir/ipv4-$country-advertised"
}

ripe(){
  if ! curl -o "$checksum" "$checksum_url"; then
    error "failed to download checksum file"
  fi

  if [ -f "$checksum_prev" ] && diff -q "$checksum" "$checksum_prev"; then
    return
  fi

  if curl -o "$table" "$table_url"; then
    if ! (cd "$state_dir"; md5sum -c "$checksum"); then
      error "checksum mismatch"
      return 2
    fi
    mv "$checksum" "$checksum_prev"
    for country in $countries; do
      for family in $families; do
        case $family in
        "ipv4")
          ripe_process_ipv4 $country "$table" "$state_dir"
          ;;
        "ipv6")
          ripe_process_ipv6 $country "$table" "$state_dir"
          ;;
        *)
          echo "Family $family not known"
          return 3
        ;;
        esac
      done
    done
  else
    error "$table_url download failed"
    return 1
  fi
}

all_advertised(){
  curl -o /tmp/prefixes_adv_pool.txt https://bgp.potaroo.net/ipv4-stats/prefixes_adv_pool.txt && \
    awk '{print $1}' /tmp/prefixes_adv_pool.txt|sort -u > "$state_dir/all-advertised"
}
stats(){
  wc -l "$state_dir/ipv"?-*.@(delegated|aggregated|advertised)
}

#all_advertised 
ripe
stats
