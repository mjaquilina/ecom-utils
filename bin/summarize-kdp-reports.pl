#!/usr/bin/perl

use strict;
use warnings;

use Spreadsheet::ParseXLSX;
use Text::Iconv;

my @files = @ARGV;

my %isbns;
for my $filename (@files)
{
    my $excel  = Spreadsheet::ParseXLSX->new->parse( $filename );
    my @sheets = $excel->worksheets;
    my $sheet  = $sheets[4]; # earnings Sheet

    my ($row_min, $row_max) = $sheet->row_range;
    for my $row_idx ( $row_min .. $row_max )
    {
        if ($row_idx == 0)
        {
            # header1 - sanity check and skip
            die unless $sheet->get_cell($row_idx, 0)->unformatted eq 'Sales Period';
            next;
        }
        elsif ($row_idx == 1)
        {
            # header2 - sanity check and skip
            die unless $sheet->get_cell($row_idx, 0)->unformatted eq 'Title';
            next;
        }

        my $units_sold  = $sheet->get_cell($row_idx, 4)->unformatted;
        my $net_units   = $sheet->get_cell($row_idx, 6)->unformatted;
        my $isbn        = $sheet->get_cell($row_idx, 2)->unformatted;
        my $payout_plan = $sheet->get_cell($row_idx, 8)->unformatted;
        my $currency    = $sheet->get_cell($row_idx, 9)->unformatted;
        my $earnings    = $sheet->get_cell($row_idx, 14)->unformatted;

        if ($units_sold eq 'N/A')
        {
            # KENP - net units is actually net pages read in this case
            $net_units = $units_sold = 0;
        }

        if ($earnings eq 'N/A')
        {
            # royalties earned = 0
            $earnings = 0;
        }

        my $mode = ( $payout_plan =~ /Paperback|Expanded/ )
            ? 'Print' : 'Digital';

        next unless $earnings > 0 or $net_units > 0;

        $isbns{$isbn}{$currency}{$mode}{ net_units } ||= 0;
        $isbns{$isbn}{$currency}{$mode}{ net_units }  += $net_units;

        $isbns{$isbn}{$currency}{$mode}{ earnings } ||= 0;
        $isbns{$isbn}{$currency}{$mode}{ earnings }  += $earnings;
    }
}

print "isbn,currency,format,net units,earnings\n";
for my $isbn (sort keys %isbns)
{
    for my $currency (keys %{ $isbns{$isbn} })
    {
        for my $mode (keys %{ $isbns{$isbn}{$currency} })
        {
            print "$isbn,$currency,$mode,$isbns{$isbn}{$currency}{$mode}{net_units},$isbns{$isbn}{$currency}{$mode}{earnings}\n";
        }
    }
}

