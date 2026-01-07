### SSH Honeypot Test

> Try connecting to the honeypot SSH port using a terminal.
> You should see "Permission denied, please try again."

![ssh_test](../images/20210812135541.png)

> Check **Attack List**. It should record the username/password tried.

![ssh_result](../images/20210812135551.png)

### FTP Honeypot Test

> Connect via FTP client.

![ftp_result](../images/20210812135559.png)

### HTTP / Web Honeypot Test

> Open the honeypot port in a browser. Enter a username and password.

![web_login](../images/image-20210810203232153.png)

> It will prompt authentication failure.
> Check **Attack List** for credentials.

![web_result](../images/20210812135717.png)

### Redis Honeypot Test

> Connect via Redis Desktop Manager or `redis-cli`.

![redis_test](../images/image-20210810200645587.png)

> Check **Attack List** for details.

![redis_result](../images/1641628594371_.pic_hd.jpg)

### MySQL Honeypot Test

> Connect via MySQL client. You can execute commands (which are simulated).

![mysql_test](../images/1521628589153_.pic_hd.jpg)

> Check **Attack List**. It may capture local file read attempts if the attacker tries them.

![mysql_result](../images/1531628589485_.pic_hd.jpg)
