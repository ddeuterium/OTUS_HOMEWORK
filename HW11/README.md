# **Домашнее задание №11: PAM**



## **Задание:**

Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников.


## **Выолнено:**

- Cоздадим двух пользователей:**otusadmin**, **otususer**. Пользователь **otusadmin** будет принадлежать группе **admin_grp**:

```
sudo useradd otususer
sudo useradd otusadmin && groupadd admin_grp && usermod -a -G admin-grp otusadmin
```

- Назначим им пароли:

```
echo "1234"|sudo passwd --stdin otusadmin; echo "1234"|sudo passwd --stdin otususer
```

- Для уверенности в том, что на нашем стенде разрешен вход через ssh по паролю выполним:

```
sudo bash -c "sed -i 's/^PasswordAuthentication.*$/PasswordAuthentication yes/' /etc/ssh/sshd_config && systemctl restart sshd.service"
```
- Добавим в **/etc/pam.d/login** строку "account required pam_time.so", выполнив:

```
sudo sed -i '5i\account required pam_time.so' /etc/pam.d/login

```

А в **/etc/security/time.conf** запретим login в выходные дни для всех кроме пользователей, принадлежащих к **admin_grp**, добавив строку:

```
login ; * ; !adm_group ; Wd
```

Теперь закинем все в [Vagrantfile](./Vagrantfile)

