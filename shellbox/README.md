# #! Shellbox #

<https://github.com/hashbang/hashbang/tree/master/shellbox>

## About ##

This repo represents the basic setup for a #! shellbox.

Files in the /etc path are managed via [etckeeper](http://etckeeper.branchable.com/).

Our etckeeper repo can be found here: [shell-etc](https://github.com/hashbang/shell-etc)

## Requirements ##

  * Debian 7+

## Installation ##

To set this up on a live server, perform the following:

1. Adjust partitions to match fstab.sample

    To do this on a VPS (Super hacky but works):
    
    1. Go to the "Virtual Console" feature in your provider.
    2. Reboot to Grub bootloader screen
    3. Hit <Enter> on first boot option
    4. Add ```break=premount``` to the end of the kernel line
    5. <Ctrl-X> to boot
    6. Copy rootfs files into ram
      ```
      mkdir /mnt
      modprobe ext4
      mount /dev/sda1 /mnt
      cp -R /mnt/* /
      umount /dev/sda1
      ```
    7. Shrink rootfs and create /home partition
      ```
      e2fsck -f /dev/sda1
      resize2fs /dev/sda1 20G
      echo "d
      1
      n
      p
      1

      +20G
      w
      n
      p
      2


      " | fdisk /dev/sda1
      ```
    8. Reboot

    9. Adjust fstab to match: [fstab.sample](https://raw.githubusercontent.com/hashbang/hashbang/shellbox/master/fstab.sample)

    10. Reboot

2. Run setup script

    ```bash
    ssh $INSTANCE_IP
    wget https://raw.githubusercontent.com/hashbang/hashbang/master/shellbox/setup.sh
    bash setup.sh
    ```

## Testing ##

  You can test the setup.sh script with:

  ```
  docker-compose run -d shellbox
  ```

  And you can get a root shell into this environment with:

  ```
  docker exec -it hashbang_shellbox_1 bash
  ```
