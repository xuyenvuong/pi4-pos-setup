# Auto Upgrade Script - Update and Migration

Run this command will auto download the new script, and migrate all your old settings for `DISCORD_WEBHOOK_URL` & `GETH_PRUNE_AT_PERCENTAGE` to the newly updated script.

```Bash
$ curl -L https://raw.githubusercontent.com/xuyenvuong/pi4-pos-setup/master/scripts/auto_upgrade_migration.sh | bash
```
---

Done. You don't need to do anything else, unless you want to double check the settings for these flags: `DISCORD_WEBHOOK_URL` & `GETH_PRUNE_AT_PERCENTAGE`, then open this file:

```Bash
$ vi ~/auto_upgrade.sh
```

If you wish to change anything, feel free to do so.

---