package Mojolicious::Plugin::Alias;

use strict;
use warnings;

use Mojo::Base 'Mojolicious::Plugin';


our $VERSION = 'v0.0.2';

our $aliases = {};
our $saved_static_dispatcher;

sub aliases {
    my ($self) = @_;
    my %by_lengths = map { $_ => length $_ } keys %$aliases;
    my @aliases = sort { $by_lengths{$b} <=> $by_lengths{$a} } keys %$aliases;
    return @aliases;
}

sub alias {
    my $self  = shift;
    my $alias = shift;
    return unless ( $alias && $alias =~ m{^/.*} );
    if (@_ > 0) {
      my @args = (@_ == 1 && ! ref $_[0]) 
               ? (paths => [ @_ ])
               : @_ ;
      $aliases->{$alias} = Mojolicious::Static->new(@args);
    }
    if ($alias && exists $aliases->{$alias}) {
        return $aliases->{$alias};
    }
    return;
}

sub match {
    my ($self, $req_path) = @_;
    foreach my $alias ($self->aliases) {
        if ($req_path =~ /^$alias.*/) {
            # print STDERR "$req_path matches $alias";
            return $alias;
        }
    }
    return;
}


sub register {
    my ($self, $app, $conf) = @_;

    if ($conf) {
        while(my ($alias, $def) = each %$conf) {
           $self->alias($alias, $def);
        }
    };

    $app->hook(
        before_dispatch => sub {
            my ($c) = @_;
            my $req_path = $c->req->url->path;
            return unless (my $alias = $self->match($req_path));
            # rewrite req_path
            $req_path =~ s/^$alias//;
            $c->req->url->path($req_path);
            # change static
            my $dispatcher = $self->alias($alias);
            $saved_static_dispatcher = $c->app->static;
            $c->app->static($dispatcher);
            # Pushy? 
        } );
     $app->hook(
        after_static => sub {
            my ($c) = @_;
            if ($saved_static_dispatcher) {
                $c->app->static($saved_static_dispatcher);
                $saved_static_dispatcher = undef;
            }
        } );
}


1;
__END__

=head1 NAME

Mojolicious::Plugin::Alias - serve static files from aliased paths

=head1 SYNOPSIS

    # Mojolicious
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

=head1 AUTHOR

Dotan Dimet, C<dotan@corky.net>.

=head1 COPYRIGHT

Copyright (C) 2010, Dotan Dimet.

This program is free software, you can redistribute it and/or modify it under
the same terms as Perl 5.10.

==head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicious.org>.

=cut
