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





