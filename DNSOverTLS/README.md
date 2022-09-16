# How to enable DNS-over-TLS using systemd

1. Create the folder
```
sudo mkdir /etc/systemd/resolved.conf.d
```

2. Copy the provided file to 
```
sudo cp 50-DNSOverTLS.conf /etc/systemd/resolved.conf.d/50-DNSOverTLS.conf
```

3. Copy the script to enable/disable the DNS-over-TLS
```
cp DNSOverTLS.sh ~/bin/.
```

4. Enable DNS-over-TLS
```
DNSOverTLS --enable
```

> Note: You need to restart your connection in order to use the new configuration:
```
sudo systemctl restart NetworkManager
```


