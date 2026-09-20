
### crtsh - query crt.sh Certificate Transparency logs and extract clean subdomains
usage: crtsh [options] <domain>
options:
     -o <file>    write deduped, sorted subdomains to file (also printed to stdout)
     -w           keep wildcard entries (by default *.domain entries are dropped)
     -v           verbose; show how many entries crt.sh returned vs emitted

## examples:
   ```
   crtsh example.com
   crtsh -o subs.txt example.com
```
