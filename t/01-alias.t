use strict;
use warnings;
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use FindBin;
use File::Spec::Functions;

get '/' => 'front';
# plugin alias => { '/people/fry/photos' => $FindBin::Bin };


# plugin alias => { '/people/fry/photos' => $FindBin::Bin };

my $t = Test::Mojo->new(app);
$t->app->static->paths([catdir($FindBin::Bin, 'public')]);

plugin alias => { '/people' => {classes => ['main']} }; # order doesn't really matter - ?
plugin alias => { '/people/fry/photos' => catdir($FindBin::Bin, 'frang', 'zoop') };
plugin alias => { '/people/leela' => { paths => [ catdir($FindBin::Bin, 'frang') ] } };

$t->get_ok('/')->content_like(qr/Phone Numbers/);
for my $path (qw(/cat.png /people/fry/photos/cat.png)) {
     $t->get_ok($path)->status_is(200)->content_type_is('image/png');
}

$t->get_ok('/say.txt')->content_is("GLOOM\n");
$t->get_ok('/people/leela/say.txt')->content_is("DOOM\n");


$t->get_ok('/people/say.txt')->status_is(200)->content_is("ROOM!\n");

done_testing();

__DATA__

@@ front.html.ep
<html>
<body>
<img src="cat.png" alt="not really an image">
<a href="/people/phones.txt">Phone Numbers</a>
<img src="/people/fry/photos/cat.png">
</body>
</html>

@@ say.txt
ROOM!
