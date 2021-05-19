# @summary Basic email and SMTP setup
#
# Basic email and SMTP setup
#
# @param root_mail_target
#   To where should root mail be sent.
#   Mutually exclusive with virtual_aliases.
#
# @param virtual_aliases
#   Text content for the file /etc/postfix/virtual.
#   Mutually exclusive with root_mail_target.
#
# @param canonical_aliases
#   Text content for the file /etc/postfix/canonical.
#
# @param mydomain
#   Email domain this host is a part of. Usually just the FQDN without hostname.
#
# @param relayhost
#   SMTP server to which all remote messages should be sent.
#
# @example
#   include profile_email
class profile_email (
  Optional[ String ] $canonical_aliases,
  String[1]          $mydomain,
  String[1]          $relayhost,
  Array[ String[1] ] $required_pkgs,
  Optional[ String ] $root_mail_target,
  Optional[ String ] $virtual_aliases,
) {

  # Make sure Postfix is installed.
  ensure_packages( $required_pkgs )

  # Helpful variables
  $file_header = @(ENDHERE)
    # This file is managed by Puppet.
    # Manual changes will be lost.
    | ENDHERE

  # Determine content source for virtual_aliases file
  if $root_mail_target =~ String and $virtual_aliases =~ String {
    fail('Cannot specify both root_mail_target and virtual_aliases')
  }
  if $root_mail_target =~ Undef and $virtual_aliases =~ Undef {
    fail('Must specify exactly one of root_mail_target or virtual_aliases')
  }
  $_virtual_aliases = $root_mail_target ? {
    String[1] => "root ${$root_mail_target}",
    default   => $virtual_aliases,
  }
  # Make virtual file
  file { '/etc/postfix/virtual':
    content => join( [$file_header, $_virtual_aliases], "\n" ),
    notify  => Service[ 'postfix' ],
  }

  # Make canonical file
  if $canonical_aliases {
    file { '/etc/postfix/canonical':
      content => join( [$file_header, $canonical_aliases], "\n" ),
      notify  => Service[ 'postfix' ],
    }
  }

  # Remove old local alias for root
  mailalias { 'root':
    ensure  => absent,
    name    => 'root',
    target  => '/etc/aliases',
    notify  => Exec[ 'newaliases' ],
    require => Package[ 'postfix' ],
  }
  exec { 'newaliases':
    command     => '/usr/bin/newaliases',
    refreshonly => true,
    require     => File_line[ 'postfix_main.cf_inet_interfaces_ipv4_only' ],
  }


  # Adjust the Postfix configuration.

  ## Make sure that Postfix only expects IPv4.
  file_line { 'postfix_main.cf_inet_interfaces_ipv4_only':
    path    => '/etc/postfix/main.cf',
    replace => true,
    line    => 'inet_interfaces = 127.0.0.1',
    match   => 'inet_interfaces = localhost',
    require => Package[ 'postfix' ],
  }


  ## Add additional lines to the file that will customize it for our enterprise.
  file_line { 'postfix_myhostname':
    path    => '/etc/postfix/main.cf',
    replace => true,
    match   => '^myhostname\ =',
    line    => "myhostname = ${::fqdn}",
    notify  => Service[ 'postfix' ],
  }

  file_line { 'postfix_mydomain':
    path    => '/etc/postfix/main.cf',
    replace => true,
    match   => '^mydomain\ =',
    line    => "mydomain = ${mydomain}",
    notify  => Service[ 'postfix' ],
  }

  file_line { 'postfix_relayhost':
    path    => '/etc/postfix/main.cf',
    replace => true,
    match   => '^relayhost\ =',
    line    => "relayhost = ${relayhost}",
    notify  => Service[ 'postfix' ],
  }

  file_line { 'postfix_masquerade_exceptions':
    path    => '/etc/postfix/main.cf',
    replace => true,
    match   => '^masquerade_exceptions\ =',
    line    => 'masquerade_exceptions = root',
    notify  => Service[ 'postfix' ],
  }

  file_line { 'postfix_masquerade_classes':
    path    => '/etc/postfix/main.cf',
    replace => true,
    match   => '^masquerade_classes\ =',
    line    => 'masquerade_classes = envelope_sender, header_sender, header_recipient',
    notify  => Service[ 'postfix' ],
  }

  file_line { 'postfix_virtual_alias_maps':
    path    => '/etc/postfix/main.cf',
    replace => true,
    match   => '^virtual_alias_maps\ =',
    line    => 'virtual_alias_maps = hash:/etc/postfix/virtual',
    notify  => Service[ 'postfix' ],
  }

  file_line { 'postfix_canonical_maps':
    path    => '/etc/postfix/main.cf',
    replace => true,
    match   => '^canonical_maps\ =',
    line    => 'canonical_maps = hash:/etc/postfix/canonical',
    notify  => Service[ 'postfix' ],
  }

  #Because mydestination is empty (see the previous example), only address literals matching $inet_interfaces or $proxy_interfaces are 
  #deemed local. So "localpart@[a.d.d.r]" can be matched as simply "localpart" in canonical(5) and virtual(5). This avoids the need to 
  #specify firewall IP addresses into Postfix configuration files.


  file_line { 'postfix_remove_os_mydestination':
    ensure            => absent,
    path              => '/etc/postfix/main.cf',
    match             => '^mydestination \= \$myhostname',
    match_for_absence => true,
  }

  file_line { 'postfix_mydestination':
    path    => '/etc/postfix/main.cf',
    replace => true,
    match   => '^mydestination \=',
    line    => 'mydestination =',
    notify  => Service[ 'postfix' ],
  }


  file_line { 'postfix_myorigin':
    path     => '/etc/postfix/main.cf',
    replace  => true,
    multiple => false,
    match    => '^myorigin\ =',
    line     => "myorigin =  ${::fqdn}",
    notify   => Service[ 'postfix' ],
  }


  # Make sure Postfix is running and that it refreshes when the config is updated.
  service { 'postfix':
    ensure => 'running',
    notify => Exec[ 'postmap_canonical_aliases', 'postmap_virtual_aliases' ],
  }


  # Run postmap commands when Postfix is refreshed.
  exec { 'postmap_canonical_aliases':
    command     => '/usr/sbin/postmap /etc/postfix/canonical',
    refreshonly => true,
    require     => Package[ 'postfix' ],
  }
  exec { 'postmap_virtual_aliases':
    command     => '/usr/sbin/postmap /etc/postfix/virtual',
    refreshonly => true,
    require     => Package[ 'postfix' ],
  }

}
