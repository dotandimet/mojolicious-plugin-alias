use strict;
use warnings;
use Test::Mojo;
use Test::More;
use Mojolicious::Lite;
use FindBin;

get '/' => 'front';
plugin alias => { '/people/fry/photos' => $FindBin::Bin };

my $t = Test::Mojo->new(app);
$t->app->static->paths([$FindBin::Bin]);


$t->get_ok('/');
$t->content_like(qr/Phone Numbers/);
$t->tx->res->dom->find('img')->pluck('attr', 'src')
  ->each(sub {
     my $path = shift;
     $path = "/$path" unless ($path =~ m|^/|);
     $t->get_ok($path)->status_is(200)->content_type_is('image/png');
     # print $path, " => ", $t->tx->res->body, "\n";
   });

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
