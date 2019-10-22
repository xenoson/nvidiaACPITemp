#!/bin/sh

acpiCallDir="$HOME/iasl"

acpiCall="acpi_call"
#acpiCallRepository="https://github.com/mkottman/${acpiCall}"
acpiCallRepository="https://github.com/semihalf-duda-patryk/${acpiCall}"
acpiCallModule="${acpiCallDir}/${acpiCall}/acpi_call.ko"
callnode="/proc/acpi/call"

NvidiaSmiCmd="nvidia-smi"
NvidiaSmiTemp="-q -d TEMPERATURE"
NvidiaSmiLoop="-l"

#Machine depended Compaq 8710w
#sensor to read acpi temp via fs
fakeSensor="/sys/class/thermal/thermal_zone0/temp"
fakeSensorTripPoints="/sys/class/thermal/thermal_zone0/trip_point_?_temp"
#acpi function to call for setting this value
acpiFunction="\_SB.C003.C096.C14B.NVIF"
#arguments for acpi function, temp value converted to hex will be appended
acpiFunctionArguments="0x8 0x2"
#fan speed can be adjusted by setting this Value
#fan speed can be read from /sys/class/thermal/thermal_zone3/temp or sensors command
#the unit °C is wrong, it is speed setting in %
fanSpeedSensor="/sys/class/thermal/thermal_zone3/temp"

#this works with trip points

#30 50 55 60 88
#30 50 70 85 100%

#values above this trip point result in emergency shutdown
criticalTripPoint="/sys/class/thermal/thermal_zone0/trip_point_0_temp"



getFanSpeed() {
  local fanSpeed="$(cat "$fanSpeedSensor")"
  echo "${fanSpeed%000}"
}

getFakeSensorTemp() {
  local temp=$(cat "$fakeSensor")
  echo "${temp%000}"
}

extractGPUTempFromSMIOutputByLine() {
#nvidia-smi output example
#        GPU Current Temp            : 60 C
  local line="$1"
  lineLength=${#line}
  line="${line#*GPU Current Temp*: }"
  line="${line%C*}"
  if [ ${#line} -lt $lineLength ]
  then
    printf %s "$line"
  else
    printf %s "invalid"
  fi
}

getGPUTemp() {
  local output="$($NvidiaSmiCmd $NvidiaSmiTemp)"
  local IFS="$(printf "\nx")"
  IFS="${IFS%x}"
  for outputLine in $output
  do
    local temp=$(extractGPUTempFromSMIOutputByLine $outputLine)
    if [ "$temp" != "invalid" ]
    then
      echo $temp
      return 0
    fi
  done
  return 1
}

getTripPointsUpDown() {
  local up
  local down
  for tripPoint in $fakeSensorTripPoints
  do
    local trip="$(cat "$tripPoint")"
    trip="${trip%000}"
    #[ $verbose -eq 1 ] && echo "trip: $trip " >&3
    if [ $trip -ge $(getFakeSensorTemp) ]
    then
      local previous=$trip
    else
      [ $verbose -eq 1 ] && echo "one up is $previous from $(getFakeSensorTemp)" >&3
      up=$previous
    fi
    
    if [ $trip -le $(getFakeSensorTemp) ]
    then
      [ $verbose -eq 1 ] && echo "one down is $trip from $(getFakeSensorTemp)" >&3
      down=$trip
      break
    fi
  done
  printf %s "$up:$down"
  return 0
}

reportAllTripPoints() {
  for tripPoint in $fakeSensorTripPoints
  do
    local trip="$(cat "$tripPoint")"
    trip="${trip%000}"
    [ $verbose -eq 1 ] && echo "trip: $trip " >&3
  done
}

gitCloneAcpiCall() {
  local BaseDir="$(pwd)"
  if [ -d "$acpiCallDir" ]
  then
    cd "$acpiCallDir" || { echo "Error with directory" >&2; return 1; }
  else
    mkdir "$acpiCallDir" || { echo "Error with making new directory" >&2; return 1; }
    cd "$acpiCallDir" || { echo "Error with directory" >&2; return 1; }
  fi

  git clone "$acpiCallRepository" || { echo "Error with git clone" >&2; cd "$BaseDir"; return 1; }
  #hack 20190415 this fork has the 4.15 compilation issue fix in a seperate branch
  git checkout acpi_package || { echo "Error with git checkout" >&2; cd "$BaseDir"; return 1; }
}

makeCompileAcpiCallModule() {
  local BaseDir="$(pwd)"
  if [ -d "${acpiCallDir}/${acpiCall}" ]
  then
    cd "${acpiCallDir}/${acpiCall}" || { echo "Error with directory" >&2; return 1; }
  else
    gitCloneAcpiCall || { echo "Error git cloning failed" >&2; return 1; }
    cd "${acpiCallDir}/${acpiCall}" || { echo "Error with directory" >&2; return 1; }
  fi
  make clean
  make || { echo "Error with make" >&2; cd "$BaseDir"; return 1; }
}

init() {
  if ! grep -q "${acpiCall}" /proc/modules
  then 
    if ! sudo insmod "$acpiCallModule"
    then
      echo "Error with module, trying to recompile..." >&2
      if makeCompileAcpiCallModule
      then
        sudo insmod "$acpiCallModule" || { echo "Error with module after successful recompilation!" >&2; return 1; }
      else
        echo "Error not able to compile module, init failed." >&2
        return 1
      fi
    fi
  fi
  return 0
}

pkillSubprocesses() {
  [   "$1" = "" -a $verbose -eq 1 ] && echo "killing all subprocesses of PID $$" >&3
  [ ! "$1" = "" -a $verbose -eq 1 ] && echo "killing $1 as a subprocesses of PID $$" >&3
  pkill -P $$ $1
  case $? in
    0) [ $verbose -eq 1 ] && echo "One or more processes matched the criteria." >&3; return 0 ;;
    1) [ $verbose -eq 1 ] && echo "No processes matched." >&3;return 1 ;;
    2) [ $verbose -eq 1 ] && echo "Syntax error in the command line." >&3; return 2 ;;
    3) [ $verbose -eq 1 ] && echo "Fatal error: out of memory etc." >&3; return 3 ;;
  esac
}

cleanup() {
  if [ ! "$1" = "regular" ] 
  then
    [ $verbose -eq 1 ] && echo "trapped SIG" >&3
    pkillSubprocesses
  else
    [ $verbose -eq 1 ] && echo "regular exit" >&3
  fi

  if grep -q "${acpiCall}" /proc/modules
  then
    [ $verbose -eq 1 ] && echo "cleaning up module" >&3
    sudo rmmod "$acpiCallModule" || { echo "error removing the module" >&2; return 1; }
  else
    [ $verbose -eq 1 ] && echo "no module" >&3
  fi

  echo
  exit 0
}

checktemp() {
  #some checks for reasonable temp values
  local temp=$(printf "%d" "${1}")
  local mintemp=20
  local maxtemp="$(cat "$criticalTripPoint")"
  maxtemp="${maxtemp%000}"
  maxtemp=$((maxtemp-1)) #values above trippoint0 result in emergency shutdown
  if [ ${#temp} -ge 2 -a ${#temp} -le 3 ]
  then
    if [ $temp -gt $mintemp -a $temp -lt $maxtemp ]
    then
      echo "$temp"
      #[ $verbose -eq 1 ] && echo "temp $temp is ok" >&3
      return 0
    elif [ $temp -le $mintemp ]
    then
      echo "$mintemp"
      echo "temp $temp is dubious, settig mintemp $mintemp" >&2
      return 0
    elif [ $temp -ge $maxtemp ]
    then
      echo "$maxtemp"
      echo "temp $temp is dubious, settig maxtemp $maxtemp" >&2
      return 0
    fi
  else
    #something is wrong, take fallback value that turns fan on to prevent overheating
    echo "$maxtemp"
    echo "temp $temp is not 2 to 3 digits and probably wrong, settig maxtemp $maxtemp" >&2
    return 0
  fi
}

tempchanged() {
  if [ $1 -eq $2 ]
  then
    return 1
  else
    return 0
  fi
}

setTemp() {
  local temp=$(checktemp "$1")
  local oldtemp="$(getFakeSensorTemp)"
  
  if tempchanged "$oldtemp" "$temp"
  then
    local hextemp=$(echo "obase=16; $temp"|bc)
    
    printf %s "$oldtemp"
    if [ -e "$callnode" ]
    then
      echo "${acpiFunction} ${acpiFunctionArguments} 0x${hextemp}" | sudo tee "$callnode" > /dev/null 2>&1 || { echo "Fatal Error writing to $callnode" >&2; return 1; }
      return 0
    else
      return 1
    fi

  else
    printf %s "false"
    return 0
  fi
}


reportFanSpeed() {
  local fanSettleNotify="$1"
  local currentFanSpeed=$(getFanSpeed)
  printf %s $currentFanSpeed
  if [ "$fanSettleNotify" = "false" ]
  then
    return 0
  elif [ $currentFanSpeed -lt $fanSettleNotify ]
  then
    [ $verbose -eq 1 ] && echo "Currently we have ${currentFanSpeed}% fan speed and falling." >&3
    return 0
  elif [ $currentFanSpeed -gt $fanSettleNotify ]
  then
    [ $verbose -eq 1 ] && echo "Currently we have ${currentFanSpeed}% fan speed and rising." >&3
    return 0
  else
    [ $verbose -eq 1 ] && echo "Currently we have ${currentFanSpeed}% fan speed settled." >&3
    return 1
  fi

}


report() {
  local tempChangeNotify="$1"
  if [ "$tempChangeNotify" != "false" ]
  then
    [ $verbose -eq 1 ] && echo "Fake sensor temp was changed from ${tempChangeNotify}°C to $(getFakeSensorTemp)°C." >&3
    return 0
  else
    return 1
  fi

}

#INT for ctrl + c
trap cleanup TERM KILL INT
