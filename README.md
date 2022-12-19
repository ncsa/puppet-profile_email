# profile_email

[![pdk-validate](https://github.com/ncsa/puppet-profile_email/actions/workflows/pdk-validate.yml/badge.svg)](https://github.com/ncsa/puppet-profile_email/actions/workflows/pdk-validate.yml)
[![yamllint](https://github.com/ncsa/puppet-profile_email/actions/workflows/yamllint.yml/badge.svg)](https://github.com/ncsa/puppet-profile_email/actions/workflows/yamllint.yml)

Enable email via postfix.

## root_mail_target

The default root email address is devnull@ncsa.illinois.edu. devnull@ncsa.illinois.edu is an actual mail alias setup on NCSA’s pop server that just drops the message. This will have to be changed via hiera data in order to have root mail sent to the appropriate place.

## Email relay

To optionally support usage as an SMTP relay, you need to specify `inet_interfaces` & `mynetworks` parameters to know where to listen and relay from:
```yaml
profile_email::inet_interfaces:
  - "172.0.0.2"     # IP OF LOCAL INTERFACE TO LISTEN ON
profile_email::mynetworks:
  - "172.0.0.0/24"  # SUBNET TO ALLOW RELAYING
```

## Dependencies


## Reference

[REFERENCE.md](REFERENCE.md)
