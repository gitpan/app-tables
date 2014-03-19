package App::Tables::Provider::xls;
use Modern::Perl;
require Data::Table::Excel;

# qw< tables2xls xls2tables >;
# qw< tables2xls xls2tables >;
# use Data::Table::Excel qw< tables2xls xls2tables >;
# use Modern::Perl;

sub new {
    my $self = pop;
    state $io =
    { reader => Data::Table::Excel->can('xls2tables')
    , writer => Data::Table::Excel->can('tables2xls') }; 
    bless { %$self, %$io } , __PACKAGE__;
}

sub read {
    my ( $self ) = @_;
    my ( $data, $headers ) = $self->{reader}( $$self{base} );
    my %whole;
    @whole{@$headers} = @$data;
    \%whole;
}

sub write {
    my ( $self, $data ) = @_;
    my @headers = keys %$data;
    my @data = map { $$data{$_} } @headers; 
    $self->{writer}( $$self{base}, \@data, \@headers );
} 

package App::Tables::Provider::xlsx;
require Data::Table::Excel;
use Modern::Perl;
our @ISA = 'App::Tables::Provider::xls'; 
# use parent 'App::Tables::Provider::xls';

sub new {
    my $self = pop;
    state $io =
    { reader => Data::Table::Excel->can('xlsx2tables')
    , writer => Data::Table::Excel->can('tables2xlsx') }; 
    bless { %$self, %$io } , __PACKAGE__;
}

package App::Tables::Provider::dir;
use Modern::Perl;
use IO::All;

sub new { bless pop, __PACKAGE__ }

sub read {
    my ( $self ) = @_;
    my @headers;
    my @data = map {
        push @headers, m{ ([^/]+) $ }x; # basename
        Data::Table::fromCSV $_ 
    } glob "$$self{base}/*";
    my %whole;
    @whole{ @headers } = @data;
    \%whole
}

sub write {
    my ( $self, $data ) = @_;
    map { -d $_ or io($_)->mkpath } $$self{base};
    while ( my ( $name, $sheet) = each $data ) {
        io( "$$self{base}/$name" ) < $sheet->csv 
    }
}

package App::Tables;
# ABSTRACT: manipulation of tables from any sources 
our $VERSION = '0.1';

use Modern::Perl;
use Exporter 'import';
our @EXPORT_OK = qw<
    init
>;

our %EXPORT_TAGS =
( all=> \@EXPORT_OK );

# possible types are xls, xslx and /
# could be some urlized dsn+query stuff

sub _init_file {
    my ( $put, $type, $desc, $args ) = @_;
    { base => ($$args{$put}  || die "no data while grabbing $desc" )
    , type => ($$args{$type} || do {
        }) }
}

sub extension_of {
    (shift) ~~ qr{
        (?: (?<type> / )
            | [.] (?<type> xlsx? )
        )$
    }x and $+{type};
}

sub _file_spec {
    my ( $desc, $data, $type ) = @_;

    $data or die "no data for $desc";

    for ( $type ||= extension_of($data) || 'dir' ) {
        $_ = 'dir' if  $_ eq '/'
    }

    { base => $data
    , type => $type }

}

sub init {
    my %args = @_ ? @_ : @ARGV;

    my %conf = map {
        $args{$_}
        ? ( $_ => [ split /,/, $args{$_} ] )
        : ()
    } qw< can >;
    $conf{from} = _file_spec input  => @args{qw< from is >};
    $conf{to}   = _file_spec output => @args{qw< to will >};

    map {
        die "overwrite $_"
            if $_ eq $conf{to}{base}
    } $conf{from}{base};
    \%conf
}

sub provider {
    my $spec = shift;
    my $provider = "App::Tables::Provider::$$spec{type}";
    $provider->new( $spec )
}


1;
