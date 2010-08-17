package ObjectDB::SQL::Base;

use strict;
use warnings;

use base 'ObjectDB::Base';

use ObjectDB::SQL::Where;

__PACKAGE__->attr(is_built => 0);
__PACKAGE__->attr([qw/driver table order_by limit offset/]);
__PACKAGE__->attr(['columns'] => sub {[]});

use overload '""' => sub { shift->to_string }, fallback => 1;
use overload 'bool' => sub { shift; }, fallback => 1;

sub where {
    my $self = shift;

    # Lazy initialization
    $self->{where} ||= ObjectDB::SQL::Where->new({ driver=>$self->driver });

    # Get
    return $self->{where} unless @_;

    # Set
    $self->{where}->where(@_);

    # Rebuild
    $self->is_built(0);

    return $self;
}

sub bind {
    my $self = shift;

    # Initialize
    $self->{bind} ||= [];

    # Get
    return $self->{bind} unless @_;

    # Set
    if (ref $_[0] eq 'ARRAY') {
        push @{$self->{bind}}, @{$_[0]};
    }
    else {
        push @{$self->{bind}}, $_[0];
    }

    return $self;
}

sub escape {
    my $self = shift;
    my $value = shift;

    $value =~ s/`/\\`/g;

    return "`$value`";
}

sub to_string {
    my $self = shift;

    die 'must be overloaded';
}

1;
