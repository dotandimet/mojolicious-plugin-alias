use strict;
use warnings;
use Test::Mojo;
use Test::More;
use Mojolicious;
use FindBin;

package AliasTest;
use Mojo::Base 'Mojolicious';
use File::Spec::Functions;

sub startup {
    my $self = shift;
    my $r    = $self->routes;
    $r->route('/')->to('ctrl#index');
    $r->get('/people/leela/gloom')->to(controller => 'Ctrl', action => 'gloom');
    $self->plugin(
        alias => {
            '/people/leela' => { paths => [ catdir( $FindBin::Bin, 'kang' ) ] }
        }
    );

}

1;

package AliasTest::Ctrl;
use Mojo::Base 'Mojolicious::Controller';

sub index {
    my $self = shift;
    $self->render( text => 'BOOM!' );
}

sub gloom {
    my $self = shift;
    $self->render( text => 'gloom' );
}

package main;

my $t = Test::Mojo->new('AliasTest');

$t->get_ok('/')->content_is('BOOM!');
# dynamic route
$t->get_ok('/people/leela/gloom')->content_is('gloom', 'route overlapping alias');
# static file via alias plugin
$t->get_ok('/people/leela/say.txt')->content_is("DOOM\n", 'static file via alias');

done_testing();

