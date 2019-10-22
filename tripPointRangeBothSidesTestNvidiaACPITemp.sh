#!/bin/sh

verbose=1

settle=15

exec 3>&1

. libNvidiaACPITemp.sh

init || exit 1

#trip points change!

# 87 59 54 49 40
#100 85 70 50 30  <-coming from lower values
# 85 70 50 30  0  <-coming from higher values

#0% does not always work (probably cpu)

#100 85 70 50 30  0  <safe
# 88 60 55 50 41
#    86 58 53 48 39

tempList="88 60 55 50 41 39"
for temp in $tempList
do

  setTemp $temp || echo "setTemp failed!"
  echo
  sleep $settle
  echo "for temp: $temp we get: $(getFanSpeed)"

  count=0
  while [ -f "/sys/class/thermal/thermal_zone0/trip_point_${count}_temp" ]
  do
    trip="$(cat "/sys/class/thermal/thermal_zone0/trip_point_${count}_temp")"
    trip="${trip%000}"
    eval trip${count}='${trip}'
    echo "trip point $count is: $trip"
    counter="$counter $count"
    counterReverse="$count $counterReverse"
    count=$((count+1))
  done

done

cleanup regular || echo "cleanup failed!"

exec 3>&1


# for temp: 88 we get: 100
# trip point 0 is: 105
# trip point 1 is: 98
# trip point 2 is: 60
# trip point 3 is: 55
# trip point 4 is: 50
# trip point 5 is: 45
# trip point 6 is: 40
# for temp: 60 we get: 85
# trip point 0 is: 105
# trip point 1 is: 98
# trip point 2 is: 88
# trip point 3 is: 55
# trip point 4 is: 50
# trip point 5 is: 45
# trip point 6 is: 40
# for temp: 55 we get: 70
# trip point 0 is: 105
# trip point 1 is: 98
# trip point 2 is: 88
# trip point 3 is: 60
# trip point 4 is: 50
# trip point 5 is: 45
# trip point 6 is: 40
# for temp: 50 we get: 50
# trip point 0 is: 105
# trip point 1 is: 98
# trip point 2 is: 88
# trip point 3 is: 60
# trip point 4 is: 55
# trip point 5 is: 45
# trip point 6 is: 40
# for temp: 41 we get: 30
# trip point 0 is: 105
# trip point 1 is: 98
# trip point 2 is: 88
# trip point 3 is: 60
# trip point 4 is: 55
# trip point 5 is: 50
# trip point 6 is: 45
# for temp: 39 we get: 30
# trip point 0 is: 105
# trip point 1 is: 98
# trip point 2 is: 88
# trip point 3 is: 60
# trip point 4 is: 55
# trip point 5 is: 50
# trip point 6 is: 45

