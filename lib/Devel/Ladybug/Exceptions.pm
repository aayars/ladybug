#
# File: lib/Devel/Ladybug/Exceptions.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#
package Devel::Ladybug::Error;

use base qw| Error::Simple |;

package Devel::Ladybug::Exceptions;

use strict;
use warnings;

#
#
#
my @__types = qw|
  AssertFailed
  ClassAllocFailed
  ClassIsAbstract
  DataConversionFailed
  DBConnectFailed
  DBQueryFailed
  DBSchemaMismatch
  FileAccessError
  GetURLFailed
  InvalidArgument
  LockFailure
  LockTimeoutExceeded
  MethodIsAbstract
  MethodNotFound
  ObjectIsAnonymous
  ObjectNotFound
  PGPDecryptFailed
  PrimaryKeyMissing
  RCSError
  RuntimeError
  StaleObject
  TimeoutExceeded
  TransactionFailed
  WrongHost
  |;

for my $type (@__types) {
  my $class = sprintf( 'Devel::Ladybug::%s', $type );

  do {
    no strict "refs";

    @{"$class\::ISA"} = "Devel::Ladybug::Error";
  };

}

1;
__END__
=pod

=head1 NAME

Devel::Ladybug::Exceptions - Defines the exceptions which may be thrown
inside of Devel::Ladybug

=head1 EXCEPTION LIST

See @__types in this package for the current list.

XXX TODO: Automate the process of turning the exception list into docs.

=head1 SEE ALSO

L<Error>, L<Devel::Ladybug::Class>

This file is part of L<Devel::Ladybug>.

=cut

