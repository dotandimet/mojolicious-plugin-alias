# Copyright (C) 2010, Dotan Dimet, based on MojoX::Dispatcher::Static,
# copyright by Sebastian Riedel.

package Mojolicious::Plugin::Alias;

use base Mojolicious::Plugin;

use strict;
use warnings;

our $VERSION = 'v0.0.1';

__PACKAGE__->attr(  [ '_aliases', '_dispatchers' ] => sub { {} } );
__PACKAGE__->attr(  '_saved_static_dispatcher'     => undef );

sub aliases {
    my ($self) = @_;
    my %by_lengths = map { $_ => length $_ } keys %{$self->_aliases};
    my @aliases = sort { $by_lengths{$b} <=> $by_lengths{$a} } keys %{$self->_aliases};
    return @aliases;
}

sub alias {
    my ($self, $alias, $path) = @_;
    if ( $alias && $alias =~ m{^/.*}
                && $path && -d $path ) {
     $self->_aliases->{$alias} = $path;   
    }
    if ($alias && exists $self->_aliases->{$alias}) {
        return $self->_aliases->{$alias};
    }
    return;
}

sub match {
    my ($self, $req_path) = @_;
    foreach my $alias ($self->aliases) {
        if ($req_path =~ /^$alias.*/) {
            return $alias;
        }
    }
    return;
}

sub dispatcher {
    my ( $self, $alias ) = @_;
    return ( $self->_dispatchers->{$alias} )
      ? $self->_dispatchers->{$alias}
      : $self->_dispatchers->{$alias} = MojoX::Dispatcher::Static->new(
        root   => $self->alias($alias),
        prefix => $alias
      );
}

sub register {
    my ($self, $app, $conf) = @_;

    if ($conf) {
        while(my ($alias, $path) = each %$conf) {
            die "Path $path not found, can't map $alias to it\n"
                unless ($self->alias($alias, $path) );
        }
    };

    $app->plugins->add_hook(
        before_dispatch => sub {
            shift; # goodbye, plugins
            my ($c) = @_;
            my $req_path = $c->req->url->path;
            return unless (my $alias = $self->match($req_path));
            my $dispatcher = $self->dispatcher($alias);
            $self->_saved_static_dispatcher($c->app->static);
            $c->app->static($dispatcher);
            # Pushy? 
        } )->add_hook(
        after_static_dispatch => sub {
            shift; # goodbye, plugins
            my ($c) = @_;
            if ($self->_saved_static_dispatcher) {
                $c->app->static($self->_saved_static_dispatcher);
            }
        } );
}


1;
__END__

=head1 NAME

Mojolicious::Plugin::Alias - serve static files from aliased paths

=head1 SYNOPSIS

    $self->  # Mojolicious
    $self->plugin('alias', { '/images' => '/foo/bar/dir/images',
                             '/css' => '/here/docs/html/css' } );

    # Mojolicious::Lite
    plugin alias => { '/images' => '/ftp/pub/images' };

=head1 DESCRIPTION

L<Mojolicious::Plugin::Alias> extends the MojoX dispatcher for static files to
serve files from either a root directory or using a set of aliases that map URL
path parts to directories on the server.

When developing with the stand-alone webserver, this module allows you to
mimic server paths that might be used in your templates. 

=head1 CONFIGURATION

When installing the plugin, pass a reference to a hash of aliases (server
paths) and the directories to map to them. Installing the plugin
($plugin->register) will fail if these paths can't be found, or if the alias
doesn't start with a leading slash.

=head1 BUGS

It doesn't handle file not found errors properly :-(

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
