#/bin/sh
set -e

state_dir="/var/lib/country-prefixes"
country=RU

next_hop=1
table=7
prefixes="$state_dir/ipv4-$country.aggregated"
routes="$state_dir/ipv4-$country.routes"
routes_extra="34.67.153.160"

default="$(ip -j route show table main proto dhcp default)"
gw="$(echo "$default"|jq -r '.[0]|.gateway')"
iface="$(echo "$default"|jq -r '.[0]|.dev')"

awk -v table="$table" -v next_hop="$next_hop" \
  '{print "route replace table", table, $1, "nhid", next_hop}' \
  "$prefixes" > "$routes"

for p in $routes_extra; do
  echo "route replace table $table $p nhid $next_hop" >> "$routes"
done

ip nexthop replace id $next_hop via $gw dev $iface

wc -l "$routes"
echo `ip route show table $table|wc -l`" in fib"
time -f "%e sec to load fib" ip -batch "$routes"
echo `ip route show table $table|wc -l`" in fib"
