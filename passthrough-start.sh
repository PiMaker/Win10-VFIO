#!/bin/bash

if [[ $UID -ne 0 ]]; then
	sudo -E bash $0 "$@"
	exit $?
fi

# Necessary for parameter usage in cleanup()
export TMP_PARAMS="$*"

# Perform cleanup after shutdown
cleanup () {

	# Restore screen config (needed to reset main monitor which turns off for whatever reason)
	#ddcutil --display 1 setvcp 60 3
	sudo -u pi -E /usr/share/xrandr-config.sh

	# Return CPU power management to default
	pstate-frequency --set -p auto -n 50

	if [[ $TMP_PARAMS == *'--keep-hugepages'* ]]
	then
		echo "Skipping hugepage deletion..."
	else
		echo "Deleting hugepages..."
		echo "0" > /proc/sys/vm/nr_hugepages
	fi

	# Kill all background processes
	killall scream-pulse || true
	killall synergyc || true

	# Restart polybar on main monitor
	#pkill polybar

	# Reset cset
	echo "Resetting cset groups..."
	cset shield --reset

	echo "Removing libvirt cgroup slice..."
	sleep 2
	rmdir /sys/fs/cgroup/cpuset/machine.slice

	echo "Undoing kernel optimizations..."
	echo fff > /sys/devices/virtual/workqueue/cpumask
	echo fff > /sys/devices/virtual/workqueue/writeback/cpumask
	echo 950000 > /proc/sys/kernel/sched_rt_runtime_us
	sysctl vm.stat_interval=1
        sysctl -w kernel.watchdog=1

	#killall polybar
	sudo -u pi -E sh -c "/home/pi/.config/polybar/bar_launch.sh > /dev/null 2>&1 &disown"
	sleep 2
}


if [[ $TMP_PARAMS == *'--cleanup'* ]]
then
	echo "Cleanup only requested!"
	cleanup
	exit 0
fi


# CPU governor settings (keep CPU frequency up, might not work on older CPUs - use cpupower for those)
pstate-frequency --set -p max


# Hugepages config
export HUGEPAGES=11000

# Note that allocating hugepages after boot has a chance to fail. If continuous memory
# cannot be allocated, a reboot will be required.
export STARTING_HUGEPAGES="$(cat /proc/sys/vm/nr_hugepages)"
if [[ "$STARTING_HUGEPAGES" -lt "$HUGEPAGES" ]]; then
    # Drop caches and compact memory to free up continuous memory for huge pages
    echo 3 > /proc/sys/vm/drop_caches
    echo 1 > /proc/sys/vm/compact_memory


    echo "Allocating $HUGEPAGES hugepages..."
    echo "$HUGEPAGES" > /proc/sys/vm/nr_hugepages
    ALLOC_PAGES="$(cat /proc/sys/vm/nr_hugepages)"

    if [[ "$ALLOC_PAGES" -lt "$HUGEPAGES" ]]; then
      echo
      echo 'Not able to allocate hugepages'
      echo "Current max: $ALLOC_PAGES"
      echo

      cleanup
      exit 1
    fi
else
    echo "Hugepages already found, let's use those!"
fi

# Move polybar to secondary screen
killall polybar

# Monitor config
if [[ $TMP_PARAMS == *'--display'* ]]
then
	ddcutil --display 1 setvcp 60 1
	xrandr --output HDMI-A-0 --off
fi

# Start synergy for mouse and keyboard sharing
echo "Starting SynergyC..."
synergyc 10.0.0.251
setxkbmap de # Required because synergy doesn't load default for whatever reason. Not needed on US keyboards.

# Start Scream-Pulse receiver for audio over the NAT network
echo "Starting sound receiver..."
sudo -u pi -E sh -c "scream-pulse -i winbr0" &

sudo -u pi -E sh -c "env SYSTRAY_MON=\"DisplayPort-0\" /home/pi/.config/polybar/bar_launch.sh > /dev/null 2>&1 &disown"

# Taskset (Move all current processes to unused cores)
# Done last, so it can move synergy and scream-pulse as well
cset shield --kthread on --cpu 1-5,7-11
#echo "Setting cset groups correctly..."
echo 0 > /sys/fs/cgroup/cpuset/system/cpuset.cpu_exclusive
echo 0 > /sys/fs/cgroup/cpuset/user/cpuset.cpu_exclusive

#echo 0 > /sys/fs/cgroup/cpuset/machine.slice/cpuset.cpu_exclusive
#echo 0-11 > /sys/fs/cgroup/cpuset/machine.slice/cpuset.cpus

echo "Performing minor optimizations prior to launch..."
echo 041 > /sys/devices/virtual/workqueue/cpumask
echo -1 > /proc/sys/kernel/sched_rt_runtime_us
for i in $(pgrep '^rcuo'); do taskset -pc 0,6 $i > /dev/null; done;
for i in /sys/devices/virtual/workqueue/*/cpumask; do echo 041 > $i; done;
sysctl vm.stat_interval=120
sysctl -w kernel.watchdog=0

/home/pi/Documents/Passthru/qemu_fifo.sh &

# Start VM via virt-manager
echo "VM starting..."
virsh start win
echo

# Print status and wait for exit
while [[ $(virsh list --all | grep running) ]]; do
  echo -en "\e[1A\rVM running - " # Weirdness is for formatting
  date
  sleep 1
done

sleep 1
echo "VM has exited"

cleanup
