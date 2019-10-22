#!/bin/sh

verbose=1

exec 3>&1

. libNvidiaACPITemp.sh

init || exit 1

#this is wrong asumption
#trip points change!

count=0
while [ -f "/sys/class/thermal/thermal_zone0/trip_point_${count}_temp" ]
do
  trip="$(cat "/sys/class/thermal/thermal_zone0/trip_point_${count}_temp")"
  trip="${trip%000}"
  eval trip${count}='${trip}'
  counter="$counter $count"
  counterReverse="$count $counterReverse"
  count=$((count+1))
done


echo "reverse"

for i in $counterReverse
do
  eval trip=\$trip${i}
  setTemp $trip || echo "setTemp failed!"
  echo
  sleep 15
  echo "$i for $trip we get: $(getFanSpeed)"
done

echo "forward"

for i in $counter
do
  eval trip=\$trip${i}
  setTemp $trip || echo "setTemp failed!"
  echo
  sleep 15
  echo "$i for $trip we get: $(getFanSpeed)"
done

echo "reverse"

for i in $counterReverse
do
  eval trip=\$trip${i}
  setTemp $trip || echo "setTemp failed!"
  echo
  sleep 15
  echo "$i for $trip we get: $(getFanSpeed)"
done


trip=55
setTemp $trip || echo "setTemp failed!"
echo
echo "bonus for $trip we get: $fanSpeed"

cleanup regular || echo "cleanup failed!"

exec 3>&1

#value above trip point 0 results in shutdown
#Jul 24 17:25:15 hotbox kernel: [21990.444847] ACPI Exception: AE_AML_PACKAGE_LIMIT, Index (0x0FFFFFFFE) is beyond end of object (length 0x8) (20150930/exoparg2-424)
#Jul 24 17:25:15 hotbox kernel: [21990.444855] ACPI Error: Method parse/execution failed [\_TZ.C38C] (Node ffff8802330b6190), AE_AML_PACKAGE_LIMIT (20150930/psparse-542)
#Jul 24 17:25:15 hotbox kernel: [21990.444862] ACPI Error: Method parse/execution failed [\_TZ.C37E] (Node ffff8802330b6168), AE_AML_PACKAGE_LIMIT (20150930/psparse-542)
#Jul 24 17:25:15 hotbox kernel: [21990.444868] ACPI Error: Method parse/execution failed [\_TZ.TZ2._TMP] (Node ffff8802330b5de8), AE_AML_PACKAGE_LIMIT (20150930/psparse-542)
#Jul 24 17:25:15 hotbox kernel: [21990.444877] thermal thermal_zone0: failed to read out thermal zone (-19)


# reverse
# temp changed: 55 to 40
# 6 for 40 we get: 30
# temp changed: 40 to 45
# 5 for 45 we get: 30
# temp changed: 45 to 50
# 4 for 50 we get: 50
# temp changed: 50 to 60
# 3 for 60 we get: 85
# temp changed: 60 to 88
# 2 for 88 we get: 100
# temp changed: 88 to 98
# 1 for 98 we get: 100
# temp changed: 98 to 104
# 0 for 105 we get: 100
# forward
# 0 for 105 we get: 100
# temp changed: 104 to 98
# 1 for 98 we get: 100
# temp changed: 98 to 88
# 2 for 88 we get: 100
# temp changed: 88 to 60
# 3 for 60 we get: 85
# temp changed: 60 to 50
# 4 for 50 we get: 50
# temp changed: 50 to 45
# 5 for 45 we get: 30
# temp changed: 45 to 40
# 6 for 40 we get: 0
# reverse
# 6 for 40 we get: 0
# temp changed: 40 to 45
# 5 for 45 we get: 30
# temp changed: 45 to 50
# 4 for 50 we get: 50
# temp changed: 50 to 60
# 3 for 60 we get: 85
# temp changed: 60 to 88
# 2 for 88 we get: 100
# temp changed: 88 to 98
# 1 for 98 we get: 100
# temp changed: 98 to 104
# 0 for 105 we get: 100
# temp changed: 104 to 55
# bonus for 55 we get: 70


