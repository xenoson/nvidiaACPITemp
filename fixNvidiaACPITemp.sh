#!/bin/sh

#verbose=1
verbose=0

intervalInSec=10
keepaliveSudoCredentials=1
keepaliveSudoTimeInMin=14

#reloadModule=1 will try to reload the kernel module if callnode is found missing. otherwise will cleanup and terminate
reloadModule=1

exec 3>&1

. libNvidiaACPITemp.sh

init || exit 1

main() {
  local tempChangeNotify
  local retries=3
  
  local fanSettleNotify="false"
  fanSettleNotify=$(reportFanSpeed $fanSettleNotify)
  local fanSpeedStatus=$?
  
  local sudocounter=0

  $NvidiaSmiCmd $NvidiaSmiTemp $NvidiaSmiLoop $intervalInSec | while read line 
  do 

    local temp=$(extractGPUTempFromSMIOutputByLine "$line")

    if [ "$temp" != "invalid" ]
    then
      local retryCount=0
      local success=0
      until [ $retryCount -ge $retries -o $success -eq 1 ]
      do
        if tempChangeNotify=$(setTemp $temp)
        then
          success=1

          if [ $keepaliveSudoCredentials -eq 1 ]
          then
            sudocounter=$((sudocounter+1))
          fi

          if [ $fanSpeedStatus -eq 0 ] 
          then
            fanSettleNotify=$(reportFanSpeed $fanSettleNotify)
            fanSpeedStatus=$?
            if report $tempChangeNotify
            then
              sudocounter=0
            fi
          else
            if report $tempChangeNotify
            then
              fanSettleNotify=$(reportFanSpeed $fanSettleNotify) 
              fanSpeedStatus=$?
              sudocounter=0
            fi
          fi

          if [ $sudocounter -ge $((${keepaliveSudoTimeInMin}*60/${intervalInSec})) ]
          then
            [ $verbose -eq 1 ] && echo "renewing sudo credentials because $sudocounter iterations of $intervalInSec seconds passed." >&3
            sudo -v
            sudocounter=0
          fi


        else

          if [ $retryCount -ge $((retries-1)) -o $reloadModule -lt 1 ]
          then
            [ $verbose -eq 1 ] && echo "kernel module vanished, set reloadModule to 1 to try reloading, killing nvidia-smi to exit." >&3
            pkillSubprocesses $NvidiaSmiCmd && success=1
          else
            [ $verbose -eq 1 ] && echo "kernel module vanished, trying to reinit" >&3
            init || echo "Problem with reinit, should not happen!"
          fi

        fi
        
        retryCount=$((retryCount+1))
      done
    fi
    
  done
}

main

cleanup regular || echo "cleanup failed!"

exec 3>&-