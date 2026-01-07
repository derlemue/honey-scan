#### Database Selection

Unless you have severe resource constraints or specific environmental limitations, **we strongly recommend using MySQL or MariaDB.**

Based on extensive testing, MySQL/MariaDB enables HFish to handle the majority of production scenarios, offering superior data processing capabilities and concurrency support compared to SQLite.

> **About SQLite**

For an out-of-the-box experience, HFish uses SQLite by default. The pre-initialized database is located at `/usr/share/db/hfish.db`.

**SQLite is only suitable for feature previews or small-scale intranet deployments.**

> **Migrating from SQLite to MySQL/MariaDB**

HFish provides two ways to use MySQL/MariaDB:

1. **Initial Install**: Choose MySQL/MariaDB during the first installation.
2. **Post-Install Migration**: If you are already using SQLite, you can migrate to MySQL via the web interface. Log in as admin and navigate to the "Database Configuration" page to follow the migration guide.

![db_config](../images/image-20211116210129137.png)

`Note: HFish only supports migrating from SQLite to MySQL/MariaDB. Reverse migration is not supported.`