#### Database Configuration

Manage database connection and data retention.

> **Database Management**

HFish uses **SQLite** by default (suitable for intranet/low-traffic). For complex or high-traffic environments, we recommend **MySQL**.

You can switch from SQLite to MySQL on this page.
- Enter MySQL Host, Port, Username, Password.
- **Data Migration**: Existing data will be automatically copied to MySQL during the switch.

*Note: Migration is one-way (SQLite -> MySQL).*

> **Data Cleaning**

Manually clean up historical data to improve performance.
- Clean **All Data**.
- Clean **Data older than 7 days**.
