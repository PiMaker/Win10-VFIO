#!/bin/bash

sleep 45

if [[ $(sudo virsh list --all | grep running) ]]; then
  echo "VM running, performing action"
else
  echo "VM no longer running, aborting"
  exit 1
fi

chrt -a -f -p 99 $(pidof qemu-system-x86_64)
echo "Set QEMU execution policy!"
chrt -p $(pidof qemu-system-x86_64)

echo "Setting IRQ affinities..."
bash -c "for i in $(sed -n -e 's/ \([0-9]\+\):.*/\1/p' /proc/interrupts); do echo '0,6' > /proc/irq/$i/smp_affinity_list; done;" > /dev/null 2>&1

echo
echo
