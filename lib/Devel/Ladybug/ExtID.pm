#
# File: lib/Devel/Ladybug/ExtID.pm
#
# Copyright (c) 2009 TiVo Inc.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Common Public License v1.0
# which accompanies this distribution, and is available at
# http://opensource.org/licenses/cpl1.0.txt
#

=pod

=head1 NAME

Devel::Ladybug::ExtID - Define inter-object relationships

=head1 SYNOPSIS

  use Devel::Ladybug qw| :all |;

  create "YourApp::ChildObject" => {
    parentObjectId => Devel::Ladybug::ExtID->assert(
      "YourApp::ParentObject"
    )
  };

=head1 DESCRIPTION

Ladybug's ExtID assertions are a simple and powerful way to define
cross-object, cross-table relationships. An ExtID is a column/instance
variable which points at the ID of another object.

Extends L<Devel::Ladybug::Str>.

=head1 RELATIONSHIP DIRECTION

B<This is important.>

Always use parent id in a child object, rather than child id in a
parent object-- or else cascading operations will probably eat your
data in unexpected and unwanted ways.

=head1 PUBLIC CLASS METHODS

=over 4

=item * $class->assert([$query], @rules)

ExtID assertions are like pointers defining relationships with other
classes, or within a class to define parent/child hierarchy.

Attributes asserted as ExtID must match an id in the specified class's
database table.

If using a backing store which supports it, ExtID assertions also
enforce database-level foreign key constraints.

=back

=head1 EXAMPLES

=head2 Self-Referencing Table

Create a class of object which refers to itself by parent ID:

  #
  # File: YourApp/ParentObject.pm
  #
  use strict;
  use warnings;

  use Devel::Ladybug qw| :all |;

  create "YourApp::ParentObject" => {
    #
    # Folders can go in other folders:
    #
    parentId => Devel::Ladybug::ExtID->assert(
      "YourApp::ParentObject",
      subtype(
        optional => true
      )
    ),

    # ...
  };

Meanwhile, in caller, create a top-level object and a child object
which refers to it:

  #
  # File: test-selfref.pl
  #
  use strict;
  use warnings;

  use YourApp::ParentObject;

  my $parent = YourApp::ParentObject->new(
    name => "Hello Parent"
  );

  $parent->save;

  my $child = YourApp::ChildObject"->new(
    name => "Hello Child",
    parentId => $parent->id,
  );

  $child->save;

=head2 Externally Referencing Table

A document class, building on the above example. Documents refer
to their parent by ID:

  #
  # File: YourApp/ChildObject.pm
  #
  use strict;
  use warnings;

  use Devel::Ladybug qw| :all |;

  use YourApp::ParentObject; # You must "use" any external classes

  create "YourApp::ChildObject" => {
    parentId => Devel::Ladybug::ExtID->assert(
      "YourApp::ParentObject"
    )

  };

Meanwhile, in caller, create a node which refers to its foreign class
parent:

  #
  # File: test-extref.pl
  #
  use strict;
  use warnings;

  use YourApp::ChildObject;

  my $parent = YourApp::ParentObject->loadByName("Hello Parent");

  my $child = YourApp::ChildObject->new(
    name => "Hello Again",
    parentId => $parent->id
  );

  $child->save;

=head2 One to Many

Wrap ExtID assertions inside a L<Devel::Ladybug::Array> assertion
to create a one-to-many relationship.

  #
  # File: YourApp/OneToManyExample.pm
  #

  # ...

  create "YourApp::OneToManyExample" => {
    parentIds => Devel::Ladybug::Array->assert
      Devel::Ladybug::ExtID->assert(
        "YourApp::ParentObject"
      )
    ),

    # ...
  };

=head2 Many to One / One to One

ExtID's default behavior is to permit many-to-one relationships
(that is, multiple children may refer to the same parent by ID).
To restrict this to a one-to-one relationship, include a C<unique>
subtype argument.

  #
  # File: YourApp/OneToOneExample.pm
  #

  # ...

  create "YourApp::OneToOneExample" => {
    parentId => Devel::Ladybug::ExtID->assert(
      "YourApp::ParentObject",
      subtype(
        unique => true
      )
    ),
    
    # ...
  };

=head2 Dynamic Allowed Values

If a string is specified as a second argument to ExtID, it will be used
as a SQL query, which selects a subset of Ids used as allowed values at
runtime.

This is entirely an application-level constraint, and is not enforced
by the database when manually inserting or updating rows. Careful!

  create "YourApp::PickyExample" => {
    userId => Devel::Ladybug::ExtID->assert(
      "YourApp::Example::::User",
      "select id from example_user where foo = 1"
    ),

    # ...
  };

=cut

#
# XXX TODO ???: Add support for actions other than CASCADE; allow toggling
# of foreign key constraints; permit lazy checking of values at db rather
# than app level, that is: give the option to ignore allowed(), and let
# the DB take care of it entirely. the app would then let you set()
# invalid values, but the DB wouldn't let you save() them, which might be a
# good option for closer-to-realtime performance. The app-level check is
# still a good early indicator for data problems, but it can be a costly
# operation.
#

=pod

=head1 BUGS AND LIMITATIONS

=head2 Same-table non-GUID keys

Self-referential tables whose ID is not of type L<Devel::Ladybug::ID>
should assert an appropriate column type. This is needed because at
class creation time, Ladybug does not yet know anything about the
ID of the class being created. This workaround is only needed for
self-referential tables which have overridden their C<id> column.

You do B<not> need to do this for externally referencing tables,
since Ladybug will already know which column type to use. You do
B<not> need to do this unless the C<id> assertion was overridden.


  create "YourApp::FunkySelfRef" => {
    id => Devel::Ladybug::Serial->assert(),

    parentId => Devel::Ladybug::ExtID->assert(
      "YourApp::FunkySelfRef",
      subtype(
        columnType => "INTEGER"     # <-- eg
      )
    ),

  };

=head1 SEE ALSO

This file is part of L<Devel::Ladybug>.

=cut

package Devel::Ladybug::ExtID;

use strict;
use warnings;

use base qw| Devel::Ladybug::Str |;

sub assert {
  my $class = shift;
  my @rules = @_;

  my $externalClass = shift @rules;
  my $query         = $rules[0];

  my %parsed =
    Devel::Ladybug::Type::__parseTypeArgs( Devel::Ladybug::Type::isStr,
    @rules );

  if ( UNIVERSAL::isa( $externalClass, "Devel::Ladybug::Object" ) ) {
    #
    # We already know what the foreign column type is, so just use
    # the same type here:
    #
    $parsed{columnType} ||= $externalClass->asserts->{id}->columnType;

  } else {
    #
    # If asserting a self-referential link from a table to itself,
    # $externalClass won't exist yet, and this is a problem when
    # it comes to magically determine the column type. The solution
    # implemented below doesn't "just work" for self-ref ExtIDs which
    # are referencing a type other than Devel::Ladybug::ID (eg
    # Devel::Ladybug::Serial).
    #
    # As a workaround, callers should provide an explicit "columnType"
    # subtype arg in these cases for now. I'm not sure how else to
    # deal with this presently. This only happens for same-table ExtIDs
    # in classes which do not use Devel::Ladybug::ID for their
    # primary key, which is really an edge use case for Ladybug.
    #
    $parsed{columnType} ||= Devel::Ladybug::ID->assert->columnType;

  }

  if ( $query && !ref $query ) {
    $parsed{allowed} = sub {
      my $type  = shift;
      my $value = shift;

      return $externalClass->selectBool($query)
        || Devel::Ladybug::AssertFailed->throw(
        "Value \"$value\" is not permitted");
    };

  } else {
    $parsed{allowed} = sub {
      my $type  = shift;
      my $value = shift;

      my $memberClass = $type->memberClass;

      my $exists;

      if ( $memberClass->__useDbi ) {
        my $q = sprintf(
          q| SELECT %s FROM %s WHERE %s = %s |,
          $memberClass->__primaryKey, $memberClass->__selectTableName,
          $memberClass->__primaryKey, $memberClass->quote($value)
        );

        $exists = $externalClass->selectBool($q);
      } else {
        $exists = $memberClass->doesIdExist($value);
      }

      return $exists
        || Devel::Ladybug::AssertFailed->throw(
        "Value \"$value\" is not permitted");
    };

  }

  $parsed{memberClass} = $externalClass;

  return $class->__assertClass()->new(%parsed);
}

1;