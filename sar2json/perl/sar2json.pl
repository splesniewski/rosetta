#!/usr/bin/env perl
use warnings;
use strict;
use JSON;
use Time::Local;

################################################################
my %dJSONData;
my %dJSONMeta;
my @dJSONMetaCols;

while (my $l = <STDIN>){
    chomp($l);

    if ( $l =~ /^(Linux) (\S+) \((\S+)\)[ \s]+(\d+)\/(\d+)\/(\d+)/ ){
        (
         $dJSONData{"operatingsystem"},
         $dJSONData{"operatingsystemversion"},
         $dJSONData{"hostname"},
         $dJSONMeta{"month"},
         $dJSONMeta{"dom"},
         $dJSONMeta{"year"},
        )=($l=~/^(Linux) (\S+) \((\S+)\)[ \s]+(\d+)\/(\d+)\/(\d+)/);

    }elsif ($l =~ /^(\d+):(\d+):(\d+) (\S\S)\s+IFACE\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/){
        my ($hour, $minute, $second, $meridiem);

        (
         $hour, $minute, $second, $meridiem,
         @dJSONMetaCols
        )=($l=~/^(\d+):(\d+):(\d+) (\S\S)\s+(IFACE)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/);

    }elsif ($l =~ /^(\d+):(\d+):(\d+) (\S\S)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/){
        my %recordMeta;
        my @recordData;

        (
         $recordMeta{"hour"},
         $recordMeta{"minute"},
         $recordMeta{"second"},
         $recordMeta{"meridiem"},
         $recordMeta{"IFACE"},
         @recordData
        )=($l=~/^(\d+):(\d+):(\d+) (\S\S)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/);

        my @ZT_date=(
            $recordMeta{'second'},
            $recordMeta{'minute'},
	    (($recordMeta{"meridiem"}=~/am/i)?($recordMeta{"hour"}==12?0:$recordMeta{"hour"}):($recordMeta{"hour"}==12?12:$recordMeta{"hour"}+12)),
            $dJSONMeta{'dom'},
            $dJSONMeta{'month'}-1,
            $dJSONMeta{'year'}-1900,
            ,,,);
        my $timestamp=timelocal(@ZT_date);

	foreach my $n (0..6){ $dJSONData{'data'}{$timestamp}{$recordMeta{"IFACE"}}{$dJSONMetaCols[$n+1]}=$recordData[$n]; }

    }elsif ($l =~ /^Average:/){ # ignore the 'Average' lines at the end.
    }elsif ($l =~ /^$/){ # skip blank
    }else{
        printf(STDERR "NOT PARSED:%s\n", $l);
    }
}

printf("%s",encode_json(\%dJSONData));
