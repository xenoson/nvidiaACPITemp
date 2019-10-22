#!/bin/sh

verbose=1
#verbose=0

settleSec=2

exec 3>&1

. libNvidiaACPITemp.sh

#init || exit 1

main() {

  reportAllTripPoints
  tmp=$(getTripPointsUpDown)
  unset tmp
  
  local fanSettleNotify="false"
  #[ $verbose -eq 1 ] && echo "current fan speed: $(getFanSpeed)%"
  #one for init, one for output
  [ $verbose -eq 1 -a $settleSec -gt 0 ] && fanSettleNotify=$(reportFanSpeed $fanSettleNotify) && fanSettleNotify=$(reportFanSpeed $fanSettleNotify) 
  #this one is for init, no output
  ##[ $verbose -eq 1 -a $settleSec -gt 0 ] && reportFanSpeed 

  [ $verbose -eq 1 ] && echo "Fake sensor temp $(getFakeSensorTemp)°C." >&3
  [ $verbose -eq 1 ] && echo "GPU Temp: $(getGPUTemp)°C." >&3

}

main "$@"

#cleanup regular || echo "cleanup failed!" >&2

exec 3>&-

