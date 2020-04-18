# **Домашнее задание №11: PAM**



## **Задание:**

Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников.


##**Выолнено:**

- Cоздадим двух пользователей:**otusadmin**, **otususer**. Пользователь **otusadmin** будет принадлежать группе **admin**:

```
sudo useradd otususer
sudo useradd otusadmin && groupadd admin && usermod -a -G admin otusadmin
```

- Назначим им пароли:

```
echo "hw11"|sudo passwd --stdin otusadmin; echo "hw11"|sudo passwd --stdin otususer
```

- Для уверенности в том, что на нашем стенде разрешен вход через ssh по паролю выполним:

```
sudo bash -c "sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service"
```
- Добавим в **/etc/pam.d/login** следующие строки:

```
account    [success=1 default=ignore] pam_succeed_if.so user ingroup admin
account    required     pam_time.so
```

А в **/etc/security/time.conf** запретим login в выходные дни:

```
login;*;*;Wk0000-2400
```


![Screen1](./screens/Screen1.png)


