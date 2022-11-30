#/bin/sh
set -e

state_dir="/var/lib/coutry-prefixes"
country=RU

prefixes="$state_dir/ipv6-$country.delegated"
routes="$state_dir/ipv6-$country.routes"
next_hop=2
table=17

test_ip=`dig +short dns.google. AAAA|head -1`
default="$(ip -6 -j route show table main default)"
gw="$(echo "$default"|jq -r '.[0]|.gateway')"
iface="$(echo "$default"|jq -r '.[0]|.dev')"

awk -v table="$table" -v next_hop="$next_hop" \
  '{print "route replace table", table, $1, "nhid", next_hop}' \
  "$prefixes" > "$routes"

ip -6 nexthop replace id $next_hop blackhole

wc -l "$routes"
echo `ip -6 route show table $table|wc -l`" in fib"
time -f "%e sec to load fib" ip -6 -batch "$routes"
echo `ip -6 route show table $table|wc -l`" in fib"
