#!/usr/bin/perl

use strict;
use warnings;
use Text::CSV;

my @files = @ARGV;

my %isbns;
for my $filename (@files)
{
    my $csv    = Text::CSV->new({ sep_char => "\t" });
    open (my $fh, '<', $filename) or die $!;
    my $next_idx = 0;
    while (my $row = $csv->getline($fh))
    {
        $next_idx++;
        next if $next_idx == 1; # header

        my $isbn      = $row->[66]; # isbn_13, col BO
        my $net_units = $row->[50]; # MTD_net_quantity, col AY
        my $earnings  = $row->[52]; # MTD_net_pub_comp, col BA
        my $currency  = $row->[39]; # reporting_currency, col AN

        next unless $net_units > 0 or $earnings > 0;

        $isbns{$isbn}{$currency}{ net_units } ||= 0;
        $isbns{$isbn}{$currency}{ net_units }  += $net_units;

        $isbns{$isbn}{$currency}{ earnings } ||= 0;
        $isbns{$isbn}{$currency}{ earnings }  += $earnings;
    }
}

print "isbn,currency,format,net units,earnings\n";
for my $isbn (sort keys %isbns)
{
    for my $currency (keys %{ $isbns{$isbn} })
    {
        print "$isbn,$currency,$isbns{$isbn}{$currency}{net_units},$isbns{$isbn}{$currency}{earnings}\n";
    }
}

