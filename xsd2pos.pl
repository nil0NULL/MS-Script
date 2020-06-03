#!perl

use strict;
use warnings;
use Getopt::Long;
use MaterialsScript qw(:all);

my $cart;
GetOptions('cartesian' => \$cart);
print "Cartesian Coordinations Used\n" if ($cart);

if( ! scalar(@ARGV) ){
    $ARGV[0] = "."
}

for my $doc (@ARGV){
    if( -f $doc ){
	trans(filename => $doc, cf => $cart) if ( $doc =~ /xsd$/i );
    }elsif( -d $doc ){
	opendir(my $dh, $doc) or die "Can't Open Direction $doc $! \n";
	while( readdir $dh ){
	    trans(filename => "$doc/$_" , cf => $cart) if ( /xsd$/i );
	}
	closedir $dh;
    }
}

sub trans{
    my %opt = @_;
    my $doc = $opt{filename};
    my $cart = $opt{cf};

    my $inf = $Documents{$doc};
    my $outf = Documents->New("POSCAR.txt");

    my $sc=1.0;
    $outf->Append(sprintf "%s %s %d\n", $inf->Name, $inf->Lattice3D->GroupName, $inf->Lattice3D->SpaceGroupITNumber);
    $outf->Append(sprintf "%5.3lf\n", $sc);
    $outf->Append(sprintf "%15.6lf %15.6lf %15.6lf\n", $_->X, $_->Y, $_->Z) for ($inf->Lattice3D->VectorA, $inf->Lattice3D->VectorB, $inf->Lattice3D->VectorC);
    my @atoms = sort {$a->ElementSymbol cmp $b->ElementSymbol} @{$inf->UnitCell->Atoms};
    my %elements = ();
    ++$elements{$_->ElementSymbol} for @atoms;
    $outf->Append(sprintf "%8s", $_) for sort (keys %elements);
    $outf->Append(sprintf "\n");
    $outf->Append(sprintf "%8d", $elements{$_}) for sort (keys %elements);
    $outf->Append(sprintf "\n");
    if( $cart ){
	$outf->Append(sprintf "Cartesian\n");
	$outf->Append(sprintf "%15.6lf %15.6lf %15.6lf\n", $_->XYZ->X, $_->XYZ->Y, $_->XYZ->Z) for @atoms;
    }else{
	$outf->Append(sprintf "Direct\n");
	$outf->Append(sprintf "%15.6lf %15.6lf %15.6lf\n", $_->FractionalXYZ->X, $_->FractionalXYZ->Y, $_->FractionalXYZ->Z) for @atoms;
    }
    $outf->Close;
    #$doc =~ s/xsd$/POSCAR/i;
    #print $doc;
    rename "POSCAR.txt", $doc =~ s/xsd$/POSCAR/ir;
    $inf->Close;
}
