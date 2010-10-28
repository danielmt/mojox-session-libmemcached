package MojoX::Session::Store::Libmemcached;
$MojoX::Session::Store::Libmemcached::VERSION = 0.10;

use strict;
use warnings;

use base 'MojoX::Session::Store';

use Memcached::libmemcached;
use MIME::Base64;
use Storable qw/nfreeze thaw/;

__PACKAGE__->attr('handle');
__PACKAGE__->attr('server' => 'localhost:11211');
__PACKAGE__->attr('___expiration___');

sub new {
    my $class = shift;

    my $self = $class->SUPER::new(@_);
    bless $self, $class;

    $self->handle(Memcached::libmemcached->new());

    my ($host, $port) = split(/:/, $self->server);

    unless ($self->handle->memcached_server_add($host, $port)) {
        $self->app->log->error("failed to add server $host:$port");
    }
    
    return $self;
}

sub create {
    my ($self, $sid, $expires, $data) = @_;

    if ($data) {
        $data->{___expiration___} = $expires;
        $data = encode_base64(nfreeze($data));
    }

    return $self->handle->memcached_set($sid, $data, $expires);
}

sub update {
    my ($self, $sid, $expires, $data) = @_;

    if ($data) {
        $data->{___expiration___} = $expires;
        $data = encode_base64(nfreeze($data));
    }

    return $self->handle->memcached_replace($sid, $data, $expires);
}

sub load {
    my ($self, $sid) = @_;

    my $data_base64 = $self->handle->memcached_get($sid);
    return unless $data_base64;

    my $data = thaw(decode_base64($data_base64));

    $self->___expiration___(delete $data->{___expiration___});

    return ($self->___expiration___, $data);
}

sub delete {
    my ($self, $sid) = @_;

    return $self->handle->memcached_delete($sid);
}

1;
__END__

=head1 NAME

MojoX::Session::Store::libmemcached - Memcached Store for MojoX::Session

=head1 SYNOPSIS

    my $session = MojoX::Session->new(
        store => MojoX::Session::Store::libmemcached->new(handle => $memc),
        ...
    );

    or

    my $session = MojoX::Session->new(
        store => MojoX::Session::Store::libmemcached->new(server => 'host:port'),
        ...
    );

=head1 DESCRIPTION

L<MojoX::Session::Store::libmemcached> is a store for L<MojoX::Session> that stores a
session in Memcached.

=head1 ATTRIBUTES

L<MojoX::Session::Store::libmemcached> implements the following attributes.

=head2 C<handle>

    my $memc = $store->handle;
    $store   = $store->handle($memc);

Get and set memcached handler.

=head2 C<server>

Server in format host:port. Default is 'localhost:11211'.

=head1 METHODS

L<MojoX::Session::Store::libmemcached> inherits all methods from
L<MojoX::Session::Store>.

=head2 C<new>

Overload to connect to server.

=head2 C<create>

Create session.

=head2 C<update>

Update session.

=head2 C<load>

Load session.

=head2 C<delete>

Delete session.

=head1 AUTHOR

dostioffski, C<daniel.mts@gmail.com>.

=head1 COPYRIGHT

Copyright (C) 2010, Daniel Mascarenhas.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

=cut
