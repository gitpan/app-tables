use Modern::Perl;
use YAML;
use App::Tables;
use Test::More;

for
(   [ "guess xls type from extension"
    , [ qw< testing foo.xls >        ]
    , { qw< base foo.xls type xls >  } ]

,   [ "type option confirms extension"
    , [ qw< testing foo.xls xls >    ]
    , { qw< base foo.xls type xls >  } ]

,   [ "type option infirms extension"
    , [ qw< testing foo.xls / >      ]
    , { qw< base foo.xls type dir >  } ]

) {
    my ( $desc, $args, $expected ) = @$_;
    my $got = App::Tables::_file_spec @$args;
    is_deeply $got, $expected, $desc;
} 

done_testing;


