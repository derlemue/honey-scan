#### HFish Yara Syntax

HFish uses standard Yara syntax including `rule`, `strings`, and `condition`.

**Example:**

```yara
rule detect_example
{
    strings:
        $str1 = "cmd.exe"
        $str2 = "/bin/sh"

    condition:
        any of them
}
```

This rule detects if the attack data contains "cmd.exe" or "/bin/sh".

**Resources:**
[YARA Documentation](https://yara.readthedocs.io/en/stable/)
