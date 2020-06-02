# @summary Basic email and SMTP setup

# Basic email and SMTP setup
#
# @example
#   include profile_email
class profile_email (
  String             $canonical_aliases,
  String[1]          $mydomain,
  String[1]          $relayhost,
  Array[ String[1] ] $required_pkgs,
  String             $virtual_aliases,
) {

  # Make sure Postfix is installed.
  ensure_packages( $required_pkgs )

  # Add email canonical and virtual email aliases (e.g., for root).
  file { '/etc/postfix/canonical':
    content => $canonical_aliases,
    notify  => Service[ 'postfix' ],
  }
  file { '/etc/postfix/virtual':
    content => $virtual_aliases,
    notify  => Service[ 'postfix' ],
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
    path   => '/etc/postfix/main.cf',
    line   => "myhostname = ${::fqdn}",
    notify => Service[ 'postfix' ],
  }

  file_line { 'postfix_mydomain':
    path   => '/etc/postfix/main.cf',
    line   => "mydomain = ${mydomain}",
    notify => Service[ 'postfix' ],
  }

  [ 'myorigin= $mydomain', 'mydestination =' ].each |$line| {
    file_line { "postfix_${line}":
      path   => '/etc/postfix/main.cf',
      line   => $line,
      notify => Service[ 'postfix' ],
    }
  }

  file_line { 'postfix_relayhost':
    path   => '/etc/postfix/main.cf',
    line   => "relayhost = ${relayhost}",
    notify => Service[ 'postfix' ],
  }

  $cf_lines = [
    'masquerade_exceptions = root',
    'masquerade_classes = envelope_sender, header_sender, header_recipient',
    'virtual_alias_maps = hash:/etc/postfix/virtual',
    'canonical_maps = hash:/etc/postfix/canonical'
  ]
    $cf_lines.each |$line| {
    file_line { "postfix_${line}":
      path   => '/etc/postfix/main.cf',
      line   => $line,
      notify => Service[ 'postfix' ],
    }
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
