# *Домашнее задание №3: Работа с LVM*

## *Задание:*

**на имеющемся образе /dev/mapper/VolGroup00-LogVol00 38G 738M 37G 2% /**

- уменьшить том под / до 8G
- выделить том под /home
- выделить том под /var
- /var - сделать в mirror
- /home - сделать том для снэпшотов
- прописать монтирование в fstab

*попробовать с разными опциями и разными файловыми системами (на выбор)*

- сгенерить файлы в /home/
- снять снэпшот
- удалить часть файлов
- восстановится со снэпшота
- залоггировать работу можно с помощью утилиты script


## **Ход выполнения:**


- **Уменьшаем том под / до 8G**

*ставим пакет: xfsdump - он будет необходим для снятия копии / тома:*
```
yum install xfsdump -y
```
*подготовим временный том для / раздела:*
```
pvcreate /dev/sdb
vgcreate vg_root /dev/sdb
lvcreate -n lv_root -l +100%FREE /dev/vg_root
```
*Создадим на нем файловую систему и смонтируем его*
```
mkfs.xfs /dev/vg_root/lv_root
mount /dev/vg_root/lv_root /mnt
```
*Копируем все данные с / раздела в /mnt:*
```
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
```
*Переконфигурируем grub для того, чтобы при старте перейти в новый /
Сымитируем текущий root -> сделаем в него chroot и обновим grub:*
```
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
```
*Обновим образ initrd:* 
```
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
s/.img//g"` --force; done
```
*Чтобы при загрузке был смонтирован нужный root - нужно в файле /boot/grub2/grub.cfg заменить rd.lvm.lv=VolGroup00/LogVol00 на rd.lvm.lv=vg_root/lv_root*

*Перезагружаемся с новым root томом, убедиться в этом можно посмотрев вывод lsblk:*
```
lsblk
NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINT
sda 8:0 0 40G 0 disk
|-sda1 8:1 0 1M 0 part
|-sda2 8:2 0 1G 0 part /boot
`-sda3 8:3 0 39G 0 part
 |-VolGroup00-LogVol01 253:1 0 1.5G 0 lvm [SWAP]
 `-VolGroup00-LogVol00 253:2 0 37.5G 0 lvm
sdb 8:16 0 10G 0 disk
`-vg_root-lv_root 253:0 0 10G 0 lvm /
sdc 8:32 0 2G 0 disk
sdd 8:48 0 1G 0 disk
sde 8:64 0 1G 0 disk
```

*Изменяем размер старой VG и возвращаем на него root. Для этого удаляем
старый LV на 40G и создаем новый на 8G:*
```
 lvremove /dev/VolGroup00/LogVol00
 lvcreate -n VolGroup00/LogVol00 -L 8G /dev/VolGroup00
 ```
 *Создаем на нем файловую систему, монтируем его и переносим данные:*
 ```
mkfs.xfs /dev/vg_root/lv_root
mount /dev/vg_root/lv_root /mnt
xfsdump -J - /dev/VolGroup00/LogVol00 | xfsrestore -J - /mnt
```
 
*Как и в первый раз переконфигурируем grub, но без исправлений в  /etc/grub2/grub.cfg
```
for i in /proc/ /sys/ /dev/ /run/ /boot/; do mount --bind $i /mnt/$i; done
chroot /mnt/
grub2-mkconfig -o /boot/grub2/grub.cfg
cd /boot ; for i in `ls initramfs-*img`; do dracut -v $i `echo $i|sed "s/initramfs-//g;
s/.img//g"` --force; done
```
-**Выделить том под /var - сделать в mirror**

*Перед тем, как перезагрузиться и выйти из под chroot - мы можем заодно перенести /var*

*Создадим зеркало на свободных дисках:*
```
pvcreate /dev/sdc /dev/sdd
vgcreate vg_var /dev/sdc /dev/sdd
lvcreate -L 950M -m1 -n lv_var vg_var
```

*Создаем на нем FS и перемещаем туда /var:*
```
mkfs.ext4 /dev/vg_var/lv_var
mount /dev/vg_var/lv_var /mnt
cp -aR /var/* /mnt/ # rsync -avHPSAX /var/ /mnt/
```
*На всякий случай сохраняем содержимое старого /var (можно его просто удалить):*
```
mkdir /tmp/oldvar && mv /var/* /tmp/oldvar
```
*Монтируем новый var в каталог /var:*
```
umount /mnt
mount /dev/vg_var/lv_var /var
```
*Правим fstab для автоматического монтирования /var:*
```
echo "`blkid | grep var: | awk '{print $2}'` /var ext4 defaults 0 0" >> /etc/fstab
```
*Теперь можно перезагрузиться в "новый уменþшенныйroot" и удалить временный VG:*
```
lvremove /dev/vg_root/lv_root
vgremove /dev/vg_root
pvremove /dev/sdb
```
- **Выделить том под /home**

*Выделяем том под /home таким же образом, как делали для /var:*
```
lvcreate -n LogVol_Home -L 2G /dev/VolGroup00
mkfs.xfs /dev/VolGroup00/LogVol_Home
mount /dev/VolGroup00/LogVol_Home /mnt/
cp -aR /home/* /mnt/
rm -rf /home/*
umount /mnt
mount /dev/VolGroup00/LogVol_Home /home/
```

*Правим fstab для автоматического монтированиā /home*
```
echo "`blkid | grep Home | awk '{print $2}'` /home xfs defaults 0 0" >> /etc/fstab
```
- **сделать том для снапшотов снять снапшот; удалить часть файлов; восстановится со снапшота**

*Сгенерируем файлы в /home/*
```
touch /home/file{1..20}
```
*Снимаем снапшот:*
```
lvcreate -L 100MB -s -n home_snap /dev/VolGroup00/LogVol_Home
```
*Удаляем часть файлов:*
```
rm -f /home/file{11..20}
```
*Восстановление со снапшота:*
```
umount /home
lvconvert --merge /dev/VolGroup00/home_snap
mount /home
```
[Ссылка на протокол работы по основному заданию](typescript_HW_3)


