package ObjectDB::SchemaDiscoverer::mysql;

use strict;
use warnings;

use base 'ObjectDB::SchemaDiscoverer::Base';

sub discover {
    my $self = shift;
    my $dbh  = shift;

    my @columns;

    my $sth = $dbh->column_info(undef, undef, $self->table, '%');

    while (my $col_info = $sth->fetchrow_hashref) {
        push @columns, $self->unquote($col_info->{COLUMN_NAME});

        $self->auto_increment($columns[$#columns])
          if $col_info->{'mysql_is_auto_increment'};
    }

    $self->columns([sort @columns]);

    my $result = $dbh->selectall_arrayref(
        'SHOW INDEX FROM ' . $dbh->quote_identifier($self->table),
        {Slice => {}});

    ### TO DO: Support for multiple unique keys
    ### TO DO: cache data in schema files for better cgi performance
    ### Temporary hack:
    my @unique_keys =
      map $_->{'Column_name'},
      grep { !$_->{'Non_unique'} && $_->{'Key_name'} ne 'PRIMARY' } @$result;

    my @primary_key =
      map $_->{'Column_name'},
      grep { $_->{'Key_name'} eq 'PRIMARY' } @$result;

    $self->primary_key(\@primary_key);
    $self->{unique_keys}->[0] = \@unique_keys;
}

1;
