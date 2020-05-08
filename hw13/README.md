# Домашнее задание №13: Сбор и анализ логов.

## Цели занятия:

Разбираем настройку логгирования с помощью rsyslog и logrotate.
Знакомимся с модными система логгирования - ELK, graylog

## Задание:

Настраиваем центральный сервер для сбора логов
- в вагранте поднимаем 2 машины web и log
- на web поднимаем nginx
- на log настраиваем центральный лог сервер на любой системе на выбор (journald, rsyslog, elk)
- настраиваем аудит следящий за изменением конфигов нжинкса

Все критичные логи с web должны собираться и локально и удаленно
все логи с nginx должны уходить на удаленный сервер (локально только критичные)
логи аудита должны также уходить на удаленную систему



## Выолнено:

- Создал две виртуалки - **web** и **log**.

[Vagrantfile](./Vagrantfile)


1. Установил audit, audisp-plugins, rsyslog, nginx

2. Добавил правило в аудит (/etc/audit/rules.d/audit.rules):
-a exit,always -S open -F path=/etc/nginx/nginx.conf

3. В /etc/audit/auditd.conf отключил локальный лог:
write_logs = no

4. Включил пересылку сообщений аудита в локальный syslog: в файле /etc/audisp/plugins.d/syslog.conf проставил:
active = yes 

5. В конец /etc/rsyslog.conf добавил строчку для отправки всех логов на log-сервер по tcp:
*.* @@192.168.11.106:514

6. Добавил в /etc/rsyslog.d два файла: auditd.conf и nginx.conf.
В auditd.conf я останавливаю дальнейшую обработку для всех сообщений с тэгом "audispd", чтобы они не попадали в /var/log/messages и в другие стандартные логи.
В nginx.conf делаю то же самое, но только для сообщений с severity выше или равной error (severity <= 3).

7. В конфиге nginx указал кастомные настройки access_log и error_log.
access_log отправляется сразу на удалённый сервер (правда не нашёл возможности отправлять его таким образом по tcp - только по udp).
error_log уходит в локальный syslog. Локальный syslog, во-первых, всё транслирует в удалённый syslog по tcp, а во-вторых, часть сообщений пишет в локальный файл /var/log/nginx_error.log.

error_log syslog:server=localhost,facility=local7,tag=nginx_error info;
access_log syslog:server=192.168.11.106:514,facility=local7,tag=nginx_access,severity=info main;

P.S. в строке error_log указал уровень логирования "info", чтобы убедиться, что сообщения с severity ниже error действительно не логируются локально.

==================
       Log
==================

Добавил в /etc/rsyslog.conf такой блок:


module(load="imtcp" MaxSessions="500")
input(type="imtcp" port="514" ruleset="remotetcp")

module(load="imudp" MaxSessions="500")
input(type="imudp" port="514" ruleset="remoteudp")

template(name="RemoteHostTcp" type="string" string="/var/log/remote-hosts/%fromhost-ip%/%$.extlog%.tcplog")
template(name="RemoteHostUdp" type="string" string="/var/log/remote-hosts/%fromhost-ip%/%$.extlog%.udplog")
template(name="RawMsg" type="string" string="%rawmsg%\n")

ruleset(name="remotetcp") {
	set $.extlog = $programname;
	action(type="omfile"
	fileGroup="vagrant"
	dirGroup="vagrant"
	dirCreateMode="0770"
	fileCreateMode="0644"
	dynaFile="RemoteHostTcp" template="RawMsg")
}

ruleset(name="remoteudp") {
	set $.extlog = $programname;
	action(type="omfile"
	fileGroup="vagrant"
	dirGroup="vagrant"
	dirCreateMode="0770"
	fileCreateMode="0644"
	dynaFile="RemoteHostUdp" template="RawMsg")
}

# P.S. udp понадобился только потому, что я не смог заставить nginx отправлять access_log по tcp. Возможно, он этого и не умеет.
![list files jobid=id](./screens/Screen_4.png)


Материалы для выполнения ДЗ:

