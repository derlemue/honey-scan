#### Known Issues

The following issues have been identified:

1. **Antivirus Conflict (Unresolved)**: HFish may conflict with local antivirus software (e.g., Kaspersky) due to its deceptive nature.
   *Workaround*: Whitelist HFish or temporarily disable antivirus on the honeypot machine.

2. **Windows Defender Alert (Unresolved)**: When distributing decoys on Windows, HFish uses `certutil`, which may trigger Windows Defender.
   *Workaround*: Temporarily disable real-time protection or use manual download methods.

3. **ARM Compatibility (Unresolved)**: HFish does not currently run on Huawei Kunpeng 920 ARM (aarch64) CPUs due to lack of aarch32 backward compatibility.

4. **Upgrade Path (Unresolved)**: v2.5.x/2.6.x cannot automatically upgrade to v2.7.0+. Manual redeployment is required (data migration supported).

5. **Linux Node Decoy 404 (Resolved)**: Fixed in next version.
6. **MySQL Password Special Characters (Resolved)**: Fixed in next version.
7. **CentOS 32-bit Crash (Resolved)**: Fixed.
8. **Memory Leak (Resolved)**: Fixed in v3.3.4.
