#/bin/sh
D=`dirname $0`

myip(){
  curl ifconfig.me
}
sh "$D/on-01-prefixes.sh"
sh "$D/on-02-table-RU-v4.sh"
myip
sh "$D/on-04-rule-RU-v4.sh"
sh "$D/on-06-default.sh"
myip
