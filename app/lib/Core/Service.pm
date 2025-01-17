package Core::Service;

use v5.14;
use parent 'Core::Base';
use Core::Base;

sub table { return 'services' };

sub structure {
    return {
        service_id => {
            type => 'key',
        },
        name => {
            type => 'text',
            required => 1,
        },
        cost => {
            type => 'number',
            required => 1,
        },
        period_cost => {
            type => 'number',
            default => 1,
        },
        category => {
            type => 'number',
            required => 1,
        },
        children => {
            type => 'json',
            value => undef,
        },
        next => {
            type => 'number',
        },
        allow_to_order => {
            type => 'number',
        },
        max_count => {
            type => 'number',
        },
        question => {
            type => 'number',
        },
        pay_always => {
            type => 'number',
            default => 1,
        },
        no_discount => {
            type => 'number',
            default => 0,
        },
        descr => {
            type => 'text',
        },
        pay_in_credit => {
            type => 'number',
            default => 0,
        },
        config => { type => 'json', value => undef },
        deleted => {
            type => 'number',
            default => 0,
        },
    };
}

sub add {
    my $self = shift;
    if ( my $id = $self->SUPER::add( @_ ) ) {
        return get_service('service', _id => $id );
    }
    return undef;
}

sub convert_name {
    my $self = shift;
    my $name = shift;
    my $settings = shift;

    $name=~s/\$\{(\w+)\}/$settings->{ lc $1 }/gei;
    return $name;
}

sub subservices {
    my $self = shift;
    return $self->res->{children} || [];
}

sub api_subservices_list {
    my $self = shift;
    my %args = (
        service_id => undef,
        @_,
    );

    my $service = get_service('service', _id => $args{service_id} );
    return [] unless $service;

    my $list = $self->_list( where => {
        service_id => { -in => $service->subservices },
        deleted => 0,
    });

    # Making order of priority
    my @ret;
    for ( @{ $service->subservices || [] } ) {
        push @ret, $list->{ $_ };
    }

    return @ret;
}

sub delete {
    my $self = shift;
    my %args = @_;

    $self->set( deleted => 1 );
    return ();
}

sub list_for_api {
    my $self = shift;
    my %args = (
        admin => 0,
        parent => undef,
        service_id => undef,
        deleted => undef,
        @_,
    );

    unless ( $args{filter} && $args{filter}->{deleted} ) {
        $args{where} = { deleted => 0 };
    }

    if ( $args{admin} && $args{parent} ) {
        if ( my $service = get_service('service', _id => $args{parent} ) ) {
            $args{where} = { service_id => { -in => $service->subservices } };
        }
    }
    elsif ( $args{service_id} ) {
        $args{where} = { service_id => $args{service_id} };
    }

    my @arr = $self->SUPER::list_for_api( %args );
    return @arr;
}

sub api_price_list {
    my $self = shift;

    return $self->list(
        where => {
            allow_to_order => 1,
            deleted => 0,
        },
    );
}

sub create {
    my $self = shift;
    my %args = (
        service_id => undef,
        @_,
    );

    unless ( get_service('user')->authenticated->is_admin ) {
        delete $args{cost};
    }

    use Core::Billing;
    my $us = create_service( %args );

    my @ret = get_service('UserService')->list_for_api(
        usi => $us->id,
    );

    return \@ret;
}

sub settings {
    my $self = shift;

    return $self->config || {};
}

1;
