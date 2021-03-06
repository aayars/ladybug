#
# File: lib/Devel/Ladybug/Utility.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package Devel::Ladybug::Utility;

=pod

=head1 NAME

Devel::Ladybug::Utility - System functions required globally by
Devel::Ladybug

=head1 SYNOPSIS

  use Devel::Ladybug::Utility;

=head1 ENVIRONMENT

Using this module will enable backtraces for all warns and fatals. The
messages are informative and nicely formatted, but can be quite
verbose. To disable them, set the environment variable C<LADYBUG_QUIET>
to C<1>.

=head1 FUNCTIONS

=cut

use strict;

use Carp;
use Error qw| :try |;
use File::Path;
use IO::File;
use POSIX qw| strftime |;
use Scalar::Util qw| blessed |;
use YAML::Syck;

use Devel::Ladybug::Constants qw| yamlRoot scratchRoot |;
use Devel::Ladybug::Exceptions;

our $longmess = 1;    # Carp.pm long messages - 0 = no, 1 = yes

#
# Install WARN/DIE signal handlers:
#
my ( $ORIGWARN, $ORIGDIE );

if ( !$ENV{LADYBUG_QUIET} ) {
  $ORIGWARN = $SIG{__WARN__};
  $ORIGDIE  = $SIG{__DIE__};

  $SIG{__WARN__} = \&Devel::Ladybug::Utility::warnHandler;
  $SIG{__DIE__}  = \&Devel::Ladybug::Utility::dieHandler;
}

=pod

=item * loadYaml($path);

Load the YAML file at the specified path into a native Perl data
structure.

=cut

sub loadYaml {
  my $path = shift;

  return undef unless -e $path;

  my $yaml;

  open( YAML, "< $path" );
  while (<YAML>) { $yaml .= $_ }
  close(YAML);

  return YAML::Syck::Load($yaml);
}

=pod

=item * randstr()

Return a random 6-byte alphabetic string

=cut

sub randstr {

  # my @chars=('a'..'z','A'..'Z', 0..9);

  my @chars = ( 'A' .. 'F', 0 .. 9 );

  my $id;

  for ( 1 .. 6 ) { $id .= $chars[ rand @chars ]; }

  return $id;
}

=pod

=item * timestamp([$time])

Return the received unix epoch seconds as YYYY-MM-DD HH:MM:DD. Uses the
current time if none is provided.

=cut

sub timestamp {
  my $unix = shift;

  $unix ||= CORE::time();

  my @localtime = localtime($unix);

  return sprintf(
    '%i-%02d-%02d %02d:%02d:%02d %s',
    $localtime[5] + 1900,
    $localtime[4] + 1,
    $localtime[3], $localtime[2], $localtime[1], $localtime[0],
    strftime( '%Z', @localtime )
  );
}

=pod

=item * date([$time]);

Return the received unix epoch seconds as YYYY-MM-DD. Uses the current
time if none is provided.

=cut

sub date {
  my $unix = shift;

  $unix ||= CORE::time();

  my @localtime = localtime($unix);

  return sprintf( '%i-%02d-%02d',
    $localtime[5] + 1900,
    $localtime[4] + 1,
    $localtime[3],
  );
}

=pod

=item * time([$time]);

Return the received unix epoch seconds as hh:mm:ss. Uses the current
time if none is provided.

=cut

sub time {
  my $unix = shift;

  $unix ||= CORE::time();

  my @localtime = localtime($unix);

  return sprintf( '%02d:%02d:%02d',
    $localtime[2], $localtime[1], $localtime[0] );
}

=pod

=item * warnHandler([$exception])

Pretty-print a warning to STDERR

=cut

sub warnHandler {
  my $timestamp = Devel::Ladybug::Utility::timestamp();

  my $caller = caller();

  # my $message = $longmess
  # ? Carp::longmess(@_)
  # : Carp::shortmess(@_);

  my $message = Carp::shortmess(@_);

  $message = formatErrorString($message);

  my $errStr = "- Warning from $caller:\n  $message\n";

  print STDERR $errStr;
}

=pod

=item * dieHandler([$exception])

Pretty-print a fatal error to STDERR

=cut

sub dieHandler {
  my ($exception) = @_;

  die @_ if $^S;    # Only die for *unhandled* exceptions. It's Magic!
                    # See also: Error.pm

  my $timestamp = Devel::Ladybug::Utility::timestamp();

  my $type = ref($exception);

  my ( $firstLine, $message );

  if ( $type && UNIVERSAL::can( $exception, "stacktrace" ) ) {

    #
    # throw Error(message) was called:
    #
    $firstLine = "- Unhandled $type Exception:\n";

    $message =
      $longmess
      ? Carp::longmess( $exception->stacktrace() )
      : Carp::shortmess( $exception->stacktrace() );
  } else {

    #
    # die($string) was called:
    #
    $firstLine = "- Fatal error:\n";

    $message =
      $longmess
      ? Carp::longmess("$exception")
      : Carp::shortmess("$exception");
  }

  my $errStr;

  if ( $message =~ /Fatal error:/ ) {
    $errStr =
      $message
      ? formatErrorString($message)
      : "$exception";
  } else {
    $errStr =
      $message
      ? join( "  ", $firstLine, formatErrorString($message) )
      : join( "  ", $firstLine, "$exception" );
  }

  die "$errStr";
}

=pod

=item * formatErrorString($errStr)

Backtrace formatter called by error printing functions.

=cut

sub formatErrorString($) {
  my $errStr = shift;

  my $time = Devel::Ladybug::Utility::timestamp();

  $errStr =~ s/ (at .*?)\.\n/\n  ... $1\n  ... at $time\n\n/m;
  $errStr =~ s/^ at .*?\n//m;
  $errStr =~ s/ called at/,\n   /gm;
  $errStr =~ s/ at line/:/gm;
  $errStr =~ s/^\t/  /gm;
  $errStr =~ s/\s*$/\n/s;

  return $errStr;
}

=pod

=back

=head1 SEE ALSO

This file is part of L<Devel::Ladybug>.

=cut

1;
