# Upgrade MEV Boost to Latest Version

Anytime you want to upgrade your MEV Boost to the lastest version, please follow this instructions below:

```Bash
$ CGO_CFLAGS="-O -D__BLST_PORTABLE__" /usr/local/go/bin/go install github.com/flashbots/mev-boost@latest
$ mevboost-stop
$ sudo cp ~/go/bin/mev-boost /usr/local/bin
$ mevboost-start
```

Then check mevboost-log for error
```Bash
$ mevboost-log
```

If you don't see any error after a while, then you can stop the log.