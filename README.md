# evil-mail-tools
The purpose of this repo is to create a tool set to manage and validate email services.

## Email Validation Tool (emv.rb)
This is a tool inteneted to test various email endpoints.

### Usage
```
💎 Usage: emv.rb [options]
    -f, --from [ADDRESS]             SMTP from address. Defaults to --auth if fully qualified.
    -t, --to [ADDRESS]               SMTP to address. Defaults to --auth if fully qualified.
    -H, --host [ADDRESS]             Specify single hostname for outbound SMTP, POP3, IMAP and webmail.
    -i, --imap [ADDRESS]             IMAP specific hostname.
    -p, --pop [ADDRESS]              POP3 specific hostname.
    -s, --smtp [ADDRESS]             SMTP specific hostname.
    -w, --web [ADDRESS]              Webmail specific hostname.
    -k, --key [KEY]                  Zimbra preauth key.
    -m, --mx [ADDRESS]               MX hostname (Will try and resolve based on the --to domain if not specificed.)
    -a, --auth [USER NAME]           Username to authenticate as.
    -P, --pass [PASSWORD]            Password to authenticate with.
    -c, --config [FILE]              Configuration file with variables for tests.
    -C [web|pop|imap|smtp|mx|all],   Specify type of mail test. Default: all
        --check
    -S, --security [ssl|tls|none]    Perform TLS or SSL login. Default: none
    -n, --noverify                   Accept invalid SSL certificates.
    -l, --clean                      Delete recent message from inbox.
    -h, --help                       Usage options.
```

