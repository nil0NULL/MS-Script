#!perl

use strict;
use warnings;
use Getopt::Long;
use MaterialsScript qw(:all);

my $jobcard = "#p opt freq m062x 6-311g(d,p) empiricaldispersion=gd3 pop=nbo";
my $jobname = "cyclohexane";

if( ! scalar(@ARGV) ){
    $ARGV[0] = "."
}

for my $doc (@ARGV){
    if( -f $doc ){
	    print "$doc\n" if /cif$/i ;
	trans($doc) if ( $doc =~ /cif$/i );
    }elsif( -d $doc ){
	opendir(my $dh, $doc) or die "Can't Open Direction $doc $! \n";
	while( readdir $dh ){
	    print "$doc/$_\n" if /cif$/i ;
	    trans("$doc/$_") if /cif$/i ;
	}
	closedir $dh;
    }
}

sub trans
{
    my $inf = $_[0];
    my $prefix = $inf =~ s/\.cif$//ir;
    print "inf = $inf\n";
    print "prefix = $prefix\n";
    my $doc=Documents->New("${prefix}.xsd") or die "Can't Create ${prefix}.xsd\n";
    $doc->CopyFrom($Documents{$inf}) or die "Can't Open $inf\n";

    print "$inf is converting\n";

    $doc->CalculateBonds;
    $doc->GenerateLatticeDisplay(["PeriodicDisplayType"=>"Default"]);
    $doc->AssignMolecules;

    my $count=0;
    for my $mol (@{$doc->AsymmetricUnit->Molecules}){
	    ++$count;
	    my $outfname=$mol->ChemicalFormula;
	    $outfname=~s/\s+//g;
	    $outfname="$prefix-${outfname}-$count.gjf";
	    print $outfname,"\n";
	    my $fout;
	    open($fout,">","$outfname") or die "Can't Write to File: $outfname\n";
	    printf $fout "%%NProcShared=4\n";
	    printf $fout "%%Mem=1GB\n";
	    printf $fout "%s\n\n",$jobcard;
	    printf $fout "%s\n\n",$mol->ChemicalFormula;
	    printf $fout "0 1\n";
	    printf $fout "%s \t%15.6lf \t%15.6lf \t%15.6lf\n",$_->ElementSymbol,$_->X,$_->Y,$_->Z for (@{$mol->Atoms});
	    printf $fout "\n";
	    close($fout);
    }
    $doc->Delete;
}
