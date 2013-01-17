#!/usr/bin/perl
use warnings;
use strict;
use autodie;
use Data::Dump qw(dump);

# 1. dump errors with:
# 

my ( $errors, $dump ) = @ARGV;
die "usage: $0 errors.log dump.sql" unless -r $errors && -r $dump;

my $fix;
my $type;

open(my $f, '<', $errors);
while(<$f>) {
	if ( m/ERROR:  value too long for type (.+)/ ) {
		$type = $1;
	} elsif ( m/CONTEXT:  COPY (\w+), line \d+, column (\w+)/ ) {
		$fix->{$1}->{$2} = $type;
		$type = undef;
	}
}

warn "# fix ",dump($fix);

my $in_create_table = 0;

my $d;
if ( $dump =~ m/\.gz/i ) {
	open($d, '-|', "zcat $dump");
} else {
	open($d, '<', $dump);
}

while(<$d>) {
	if ( m/CREATE TABLE (\w+)/ ) {
		$in_create_table = $1;
	} elsif ( $in_create_table && m/;/ ) {
		$in_create_table = 0;
	}

	if ( $in_create_table && exists $fix->{$in_create_table} ) {
		my $column = $1 if /^\s+(\w+)/;
		if ( my $type = $fix->{$in_create_table}->{$column} ) {
			warn "FIX: [$_] $type\n";
			s/\Q$type\E/text/ || die "can't FIX $_ $type";
			chomp;
			$_ .= " -- FIXME $type\n";
		}
	}

	print;
}
