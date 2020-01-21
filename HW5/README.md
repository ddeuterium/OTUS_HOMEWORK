# **Домашнее задание №5: Инициализация системы. Systemd и SysV**

## **Задание:**

- **Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig**
- **Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно так же называться**
- **Дополнить юнит-файл apache httpd возможностьб запустить несколько инстансов сервера с разными конфигами**



## **Ход выполнения:**

- **Написать сервис, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова. Файл и слово должны задаваться в /etc/sysconfig**

    # Создадим файл с конфигурацией для сервиса в директории /etc/sysconfig - из неё сервис будет брать необходимые переменные 
    
    ![Screen_1_a](./screens/Screen_1_a.JPG)
    
    # Создадим /var/log/watchlog.log с произвольным содержимым + ключевое слово ‘ALERT’
   
   ![Screen_1_b](./screens/Screen_1_b.JPG)
   
    # Создадим скрипт 
    [/opt/watchlog.sh](./scripts/watchlog.sh)
   
   *Команда logger отправляет лог в системный журнал
   
   # Создадим юнит для сервиса 
   [/etc/systemd/system/watchlog.service](./scripts/watchlog.service)
   
   # Создадим юнит для таймера [/etc/systemd/system/watchlog.timer](./scripts/watchlog.timer)
   
   # Стартуем сервис, запускаем таймер и убеждаемся в результате:
   
   ![Screen_1_с](./screens/Screen_1_с.JPG)
   
   

-  **Из epel установить spawn-fcgi и переписать init-скрипт на unit-файл. Имя сервиса должно так же называться**
    
    # Устанавливаем spawn-fcgi и необходимые для него пакеты:
    ```
    yum install epel-release -y && yum install spawn-fcgi php php-cli mod_fcgid httpd -y
    ```
    # Раскомментируем строки с переменными в /etc/sysconfig/spawn-fcgi
    
    ![Screen_2_a](./screens/Screen_2_a.JPG)
    
    # Создадим init файл /etc/systemd/system/spawn-fcgi.service
    ![Screen_2_b](./screens/Screen_2_b.JPG)
    
    # Убеждаемся, что все успешно работает:
    ![Screen_2_c](./screens/Screen_2_c.JPG)
    
  
                                                                                         
- **Дополнить юнит-файл apache httpd возможностью запустить несколько инстансов сервера с разными конфигами**
    
    # Для запуска нескольких экземпляров сервиса будем использовать шаблон httpd@ в конфигурации файла окружения:
  ![Screen_3_a](./screens/Screen_3_a.JPG)
  
  # Создадим два файла окружения в /etc/sysconfig, в которых задаются опции для запуска веб-сервера с необходимыми конфигурационными файлами:
    ```
    # /etc/sysconfig/httpd-first
    OPTIONS=-f conf/first.conf
    # /etc/sysconfig/httpd-second
    OPTIONS=-f conf/second.conf
    ```
 # Создадим два файла конфигурации в директории /etc/httpd/conf:

    ```
    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/first.conf
    cp /etc/httpd/conf/httpd.conf /etc/httpd/conf/second.conf
    ```
 # Отредактируем файл конфигурации *second.conf* для исключения пересечения по портам и PidFiles.
    ```
    PidFile /var/run/httpd-second.pid
    Listen 8080
    ```
*Для удачного запуска, в конфигурационных файлах должны быть указаны уникальные для каждого экземпляра опции Listen и PidFile.
    
 # Запускаем и проверяем:
![Screen_3_b](./screens/Screen_3_b.JPG)                                                                                                                                                                             
