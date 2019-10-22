#!/bin/sh

verbose=1

settle=15

exec 3>&1

. libNvidiaACPITemp.sh

init || exit 1

from="$(cat "/sys/class/thermal/thermal_zone0/trip_point_6_temp")"
from="${from%000}"
to="$(cat "/sys/class/thermal/thermal_zone0/trip_point_2_temp")"
to="${to%000}"

count=$to
while [ $count -ge $from ]
do
  #echo $count
  setTemp $count || echo "setTemp failed!"
  echo
  sleep $settle
  echo "for $count we get: $(getFanSpeed)"
  count=$((count-1))
done

count=$from
while [ $count -le $to ]
do
  #echo $count
  setTemp $count || echo "setTemp failed!"
  echo
  sleep $settle
  echo "for $count we get: $(getFanSpeed)"
  count=$((count+1))
done

count=$to
while [ $count -ge $from ]
do
  #echo $count
  setTemp $count || echo "setTemp failed!"
  echo
  sleep $settle
  echo "for $count we get: $(getFanSpeed)"
  count=$((count-1))
done


cleanup regular || echo "cleanup failed!"

exec 3>&-


# for 88 we get: 100
# for 87 we get: 100
# for 86 we get: 85
# for 85 we get: 85
# for 84 we get: 85
# for 83 we get: 85
# for 82 we get: 85
# for 81 we get: 85
# for 80 we get: 85
# for 79 we get: 85
# for 78 we get: 85
# for 77 we get: 85
# for 76 we get: 85
# for 75 we get: 85
# for 74 we get: 85
# for 73 we get: 85
# for 72 we get: 85
# for 71 we get: 85
# for 70 we get: 85
# for 69 we get: 85
# for 68 we get: 85
# for 67 we get: 85
# for 66 we get: 85
# for 65 we get: 85
# for 64 we get: 85
# for 63 we get: 85
# for 62 we get: 85
# for 61 we get: 85
# for 60 we get: 85
# for 59 we get: 85
# for 58 we get: 70
# for 57 we get: 70
# for 56 we get: 70
# for 55 we get: 70
# for 54 we get: 70
# for 53 we get: 50
# for 52 we get: 50
# for 51 we get: 50
# for 50 we get: 50
# for 49 we get: 50
# for 48 we get: 30
# for 47 we get: 30
# for 46 we get: 30
# for 45 we get: 30
# for 44 we get: 30
# for 43 we get: 30
# for 42 we get: 30
# for 41 we get: 30
# for 40 we get: 30
# for 40 we get: 30
# for 41 we get: 30
# for 42 we get: 30
# for 43 we get: 30
# for 44 we get: 30
# for 45 we get: 30
# for 46 we get: 30
# for 47 we get: 30
# for 48 we get: 30
# for 49 we get: 30
# for 50 we get: 50
# for 51 we get: 50
# for 52 we get: 50
# for 53 we get: 50
# for 54 we get: 50
# for 55 we get: 70
# for 56 we get: 70
# for 57 we get: 70
# for 58 we get: 70
# for 59 we get: 70
# for 60 we get: 85
# for 61 we get: 85
# for 62 we get: 85
# for 63 we get: 85
# for 64 we get: 85
# for 65 we get: 85
# for 66 we get: 85
# for 67 we get: 85
# for 68 we get: 85
# for 69 we get: 85
# for 70 we get: 85
# for 71 we get: 85
# for 72 we get: 85
# for 73 we get: 85
# for 74 we get: 85
# for 75 we get: 85
# for 76 we get: 85
# for 77 we get: 85
# for 78 we get: 85
# for 79 we get: 85
# for 80 we get: 85
# for 81 we get: 85
# for 82 we get: 85
# for 83 we get: 85
# for 84 we get: 85
# for 85 we get: 85
# for 86 we get: 85
# for 87 we get: 85
# for 88 we get: 100
# for 88 we get: 100
# for 87 we get: 100
# for 86 we get: 85
# for 85 we get: 85
# for 84 we get: 85
# for 83 we get: 85
# for 82 we get: 85
# for 81 we get: 85
# for 80 we get: 85
# for 79 we get: 85
# for 78 we get: 85
# for 77 we get: 85
# for 76 we get: 85
# for 75 we get: 85
# for 74 we get: 85
# for 73 we get: 85
# for 72 we get: 85
# for 71 we get: 85
# for 70 we get: 85
# for 69 we get: 85
# for 68 we get: 85
# for 67 we get: 85
# for 66 we get: 85
# for 65 we get: 85
# for 64 we get: 85
# for 63 we get: 85
# for 62 we get: 85
# for 61 we get: 85
# for 60 we get: 85
# for 59 we get: 85
# for 58 we get: 70
# for 57 we get: 70
# for 56 we get: 70
# for 55 we get: 70
# for 54 we get: 70
# for 53 we get: 50
# for 52 we get: 50
# for 51 we get: 50
# for 50 we get: 50
# for 49 we get: 50
# for 48 we get: 30
# for 47 we get: 30
# for 46 we get: 30
# for 45 we get: 30
# for 44 we get: 30
# for 43 we get: 30
# for 42 we get: 30
# for 41 we get: 30
# for 40 we get: 0


# 87 59 54 49 40
#100 85 70 50 30  <-coming from lower values
# 85 70 50 30  0  <-coming from higher values
