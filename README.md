# profile_email

[![pdk-validate](https://github.com/ncsa/puppet-profile_email/actions/workflows/pdk-validate.yml/badge.svg)](https://github.com/ncsa/puppet-profile_email/actions/workflows/pdk-validate.yml)
[![yamllint](https://github.com/ncsa/puppet-profile_email/actions/workflows/yamllint.yml/badge.svg)](https://github.com/ncsa/puppet-profile_email/actions/workflows/yamllint.yml)

Enable email via postfix.

## relayhost
Options:
* `outbound-relays.ncsa.illinois.edu` (default)
  * Useful for hosts in NCSA Private IP space (172.24.0.0/13).
* `outbound-relays.techservices.illinois.edu`
  * Recommended for hosts in NCSA Public IP space (141.142.0.0/16)
    * Note: must also have a public hostname (e.g. *.illinois.edu) and
      that hostname must be set in `myhostname` and `myorigin`. The default
      settings work fine for the most common case when a node has just one
      hostname and one IP, but more care is needed when a node has more than one.

See also:
* [University of Illinois IP Spaces](https://go.illinois.edu/ipspace)
* [Email, Unauthenticated SMTP for campus](https://answers.uillinois.edu/illinois/47888)

## root_mail_target

The default root email address is devnull@ncsa.illinois.edu. devnull@ncsa.illinois.edu is an actual mail alias setup on NCSA’s pop server that just drops the message. This will have to be changed via hiera data in order to have root mail sent to the appropriate place.

## Email relay

To optionally support usage as an SMTP relay, you need to specify `inet_interfaces` & `mynetworks` parameters to know where to listen and relay from:
```yaml
profile_email::inet_interfaces:
  - "172.0.0.2"     # IP OF LOCAL INTERFACE TO LISTEN ON
profile_email::mynetworks:
  - "172.0.0.0/24"  # SUBNET TO ALLOW RELAYING
profile_email::smtpd_tls_security_level: "none"
```

## Dependencies


## Reference

[REFERENCE.md](REFERENCE.md)
