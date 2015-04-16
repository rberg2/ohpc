#!/usr/bin/env perl

use warnings;
use strict;

my @compiler_familes = ("gnu","intel");
my @mpi_families     = ("mvapich2","openmpi","impi");

my $delim="fsp";
my $merge_package_families = 0;

my @single_package_exceptions = ("lmod-defaults-intel-fsp");

sub parse_changes {
    my $infile     = shift;
    my $logMessage = shift;
    my %pkg_hash   = ();
    my %pkg_length = ();

    open(IN,"<$infile")  || die "Cannot open file -> $infile\n";

    while(<IN>) {
        my $name = "";
        my $old_version = "";
        my $version = "";

        if($_ =~ /^(\S+) (\S+) (\S+)$/) {
            $name        = $1;
            $old_version = $2;
            $version     = $3;
        } elsif ($_ =~ /^(\S+) (\S+)$/) {
            $name    = $1;
            $version = $2;
        } else {
            die("Unknown format in raw changlog files");
        }

        # Check if this is a compiler/MPI family package

        my $compiler_package = 0;
        my $mpi_package      = 0;
        my $name_base        = $1;
        
        foreach my $compiler (@compiler_familes) {
            foreach my $mpi (@mpi_families) {
                if($name =~ /(\S+)-$compiler-$delim/) {
                    die "unknown package family for compiler" unless ($mpi_package == 0);
                    $compiler_package = 1;
                    $name_base = $1;
                } elsif ($name =~ /(\S+)-$compiler-$mpi-$delim/) {
                    die "unknown package family for MPI" unless ($compiler_package == 0);
                    $mpi_package = 1;
                    $name_base = $1;
                }
            }
        }
        
        # hash the compiler/mpi packages to verify we detect the same
        # version for all combinations

        if($merge_package_families) {
	    if($compiler_package || $mpi_package) {
		if (! defined $pkg_hash{$name_base} ) {
		    $pkg_hash{$name_base} = $version;
		    if($old_version ne "") {
			print OUT $logMessage . "$name_base-*-fsp (from v$old_version to v$version)\n";
		    } else {
			print OUT $logMessage . "$name_base-*-fsp (v$version)\n";
		    }
		} else {
		    if($version ne $pkg_hash{$name_base} ) {
			print "ERROR: versions inconsistent for $name_base family\n";
			exit(1);
		    }
		}
#            print OUT $logMessage . "$name (v$version)\n";
	    } else {
		if($old_version ne "") {
		    print OUT $logMessage . "$name (v$old_version -> v$version)\n"; 
		} else {
		    print OUT $logMessage . "$name (v$version)\n";
		}
	    }
	} else {
	    if($old_version ne "") {
		print OUT $logMessage . "$name (v$old_version -> v$version)\n"; 
	    } else {
		print OUT $logMessage . "$name (v$version)\n";
	    }
	} 
    }

    close(IN);
} # end parse_changes()



my $fileout="ChangeLog";
open(OUT,">$fileout")  || die "Cannot open file -> $fileout\n";

#parse_changes("pkg-fsp.chglog-add","        * [NEW] component added   - ");
#parse_changes("pkg-fsp.chglog-upd","        * [UPD] component updated - ");
#parse_changes("pkg-fsp.chglog-del","        * [DEL] component removed - ");

### parse_changes("pkg-fsp.chglog-add","* [NEW] component added   - ");
### parse_changes("pkg-fsp.chglog-upd","* [UPD] component updated - ");
### parse_changes("pkg-fsp.chglog-del","* [DEL] component removed - ");
### 
### print OUT "   [Component Changes]\n";
### parse_changes("pkg-fsp.chglog-add","      * added   - ");
### parse_changes("pkg-fsp.chglog-upd","      * updated - ");
### parse_changes("pkg-fsp.chglog-del","      * removed - ");

print OUT "   [Component Additions]\n";
parse_changes("pkg-fsp.chglog-add","      * ");
print OUT "\n   [Component Version Changes]\n";
parse_changes("pkg-fsp.chglog-upd","      * ");
print OUT "\n   [Components Deprecated]\n";
parse_changes("pkg-fsp.chglog-del","      * ");

close(OUT);






