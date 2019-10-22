#!/bin/sh

verbose=1
#verbose=0

settleSec=2

exec 3>&1

. libNvidiaACPITemp.sh

init || exit 1

main() {
  #[ $verbose -eq 1 ] && echo "current fan speed: $(getFanSpeed)%"
  #one for init, one for output
  #[ $verbose -eq 1 -a $settleSec -gt 0 ] && fanSettleNotify=$(reportFanSpeed $fanSettleNotify) && fanSettleNotify=$(reportFanSpeed $fanSettleNotify) 
  #this one is for init, no output
  local fanSettleNotify="false"
  [ $verbose -eq 1 -a $settleSec -gt 0 ] && fanSettleNotify=$(reportFanSpeed $fanSettleNotify)

  local t=0

  case $1 in
      "up") t=$(getTripPointsUpDown); t=${t%:*} ;;
    "down") t=$(getTripPointsUpDown); t=${t#*:} ;;
      "0%") t=39 ;;
     "30%") t=45 ;;
     "50%") t=50 ;;
     "70%") t=55 ;;
     "85%") t=60 ;;
    "100%") t=88 ;;
      *"%") printf %s\\n "Valid %-values are 0%, 30%, 50%, 70% 85%, 100%, ignoring and using GPU Temp."; t=$(getGPUTemp); ;;
        "") t=$(getGPUTemp) ;;
         *) t=${1:-55} ;;
  esac

  local tempChangeNotify
  tempChangeNotify=$(setTemp $t || echo "setTemp failed!" >&2)



  if report $tempChangeNotify
  then
    [ $verbose -eq 1 ] && echo "GPU Temp: $(getGPUTemp)°C. Argument: \"$1\" results in t=$t to set" >&3
    if [ $verbose -eq 1 -a $settleSec -gt 0 ]
    then
      fanSettleNotify=$(reportFanSpeed $fanSettleNotify)
      sleep $settleSec
      while fanSettleNotify=$(reportFanSpeed $fanSettleNotify)
      do
        sleep $settleSec
        continue
      done
    fi
  else
    [ $verbose -eq 1 ] && echo "GPU Temp: $(getGPUTemp)°C. Argument: \"$1\" results in t=$t. Fake sensor temp was not changed" >&3
  fi

  echo ""

}

main "$@"

cleanup regular || echo "cleanup failed!" >&2

exec 3>&-

