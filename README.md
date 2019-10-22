# nvidiaACPITemp
fan speed control via acpi_call

These scripts were written to set and test fan speed control on an HP Compaq 8710w which seems to habe buggy firmware. Observation is that fan is often spinning at high rpm and loud. There are some complaints on the net that this notebook is always loud, especially with dual monitor. Fan is both for CPU and Nvidia GPU. Kernel fan control by CPU temp seems fine. Nvidia diver (or firmware) seems to control the fan to spin up, but never down.
This uses acpi_call module to set fan speed by calling apci functions. One of the sensors values is fan rpm in percent values (0%, 30%, 50%, 70%, 85%, 100%). Another sensors value seems to be for GPU temperature but it is rarely changed. It is changeable by calling the acpi function and it directly influences fan rpm.
fixNvidiaACPITemp.sh is the approach to always set current GPU temp into that sensor value. Not really necessary.
More useful is setNvidiaACPITemp.sh to tune down the fan to 70% or 85% after making sure the GPU clock is not at the highest.
Clocks can be changed manually:

    % nvidia-settings -a "GPUCurrentClockFreqsString=nvclock=200,memclock=200,processorclock=400"
    % nvidia-settings -a "GPUCurrentClockFreqsString=nvclock=275,memclock=301,processorclock=550"
    % nvidia-settings -a "GPUCurrentClockFreqsString=nvclock=383,memclock=301,processorclock=767"
    % nvidia-settings -a "GPUCurrentClockFreqsString=nvclock=500,memclock=799,processorclock=1250"

Percent values in the script (parameters) are not always correctly mapping to the desired output. Firmware seems to change trip points under certain circumstances. Therefore the up down parameters also do not work as expected. But it is always successful to successively try lower percent values until the fan spins one notch down. That's how I use it, the rest I don't care anymore.
