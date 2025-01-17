package Core::Template;

use v5.14;
use parent 'Core::Base';
use Core::Base;
use Template;

use Core::Utils qw(
    encode_json
);

sub table { return 'templates' };

sub structure {
    return {
        id => {
            type => 'key',
        },
        data => {
            type => 'text',
        },
        settings => { type => 'json', value => undef },
    }
}

sub parse {
    my $self = shift;
    my %args = (
        usi => undef,
        data => undef,
        task => undef,
        server_id => undef,
        event_name => undef,
        vars => {},
        START_TAG => '{{',
        END_TAG => '}}',
        @_,
    );

    my $data = $args{data} || $self->data || return '';

    if ( $args{task} && $args{task}->event ) {
        $args{event_name} //= $args{task}->event->{name};
    }

    my $vars = {
        user => get_service('user'),
        $args{usi} ? ( us => get_service('us', _id => $args{usi}) ) : (),
        $args{task} ? ( task => $args{task} ) : (),
        $args{server_id} ? ( server => get_service('server', _id => $args{server_id}) ) : (),
        config => get_service('config')->data_by_name,
        tpl => get_service('template'),
        service => get_service('service'),
        $args{event_name} ? ( event_name => uc $args{event_name} ) : (),
        %{ $args{vars} },
        ref => sub {
            my @data = @_;
            return ref $data[0] eq 'HASH' ? [ $data[0] ] : @data;
        },
    };

    my $template = Template->new({
        START_TAG => quotemeta( $args{START_TAG} ),
        END_TAG   => quotemeta( $args{END_TAG} ),
        ANYCASE => 1,
        INTERPOLATE  => 0,
        PRE_CHOMP => 1,
        # FILTERS => {
        #     toJson => sub {
        #         my $data = shift;
        #         return encode_json( $data );
        #     },
        # }
    });

    my $result = "";
    unless ($template->process( \$data, $vars, \$result )) {
        logger->error("Template rander error: ", $template->error() );
        return '';
    }

    return $result;
}

sub list_for_api {
    my $self = shift;
    my %args = (
        id => undef,
        @_,
    );

    my $template = $self->id( delete $args{id} );

    unless ( $template ) {
        logger->warning("Template not found");
        get_service('report')->add_error('Template not found');
        return undef;
    }

    return scalar $template->parse( %args );
}

sub add {
    my $self = shift;
    my %args = (
        @_,
    );

    return $self->SUPER::add(
        %args,
        data => $args{data} || delete $args{PUTDATA},
    );
}

sub set {
    my $self = shift;
    my %args = (
        @_,
    );

    return $self->SUPER::set(
        %args,
        data => $args{data} || delete $args{POSTDATA},
    );
}

1;
