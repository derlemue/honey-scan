### High-Interaction Honeypots

HFish currently provides two types of high-interaction honeypots: **High-Interaction SSH** and **High-Interaction Telnet**.

#### Test Accounts

```
root / 123456
```

*This is one of the enabled accounts for self-testing. Other accounts are managed dynamically by the HFish cloud service.*

#### How it Works

HFish High-Interaction Honeypots are deployed on our cloud infrastructure and managed by the HFish team. We use a cluster of servers with Nginx load balancing to handle traffic forwarded from your local nodes to the cloud.

![cloud_architecture](../images/image-20220105214958606.png)

In this model, **all traffic between the attacker and your local node is forwarded to the cloud honeynet**. The actual threat behavior happens in the cloud, ensuring the safety of your local environment while capturing high-fidelity interaction data.

![traffic_flow](../images/image-20220105220938586.png)

#### Usage

Cloud High-Interaction Honeypots are available in the Service Management list by default. To use them:

1. **Verify Network Connectivity**:
   - Nodes must be able to reach `zoo.hfish.net`.
   - The Management Server must be able to reach `zoo.hfish.net` and `api.hfish.net`.

2. **Add Service**:
   Simply add the High-Interaction SSH or Telnet service to your node configuration.

![add_service](../images/image-20220105221346398.png)

#### Viewing Data

The HFish Management Server polls `api.hfish.net` every 5 minutes to download interaction data derived from these high-interaction honeypots.

Data includes:
- Login attempts.
- Success/Failure status.
- Commands executed after successful login.

If samples (malware) are captured during the session, they will be listed in the download section.

![interaction_data](../images/image-20220105221536927.png)
