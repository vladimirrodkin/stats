#!/usr/bin/perl

 

=pod

 

usage:

 

show_me_my_zfs.pl [OPTIONS]

 

 

-raid                     RAID type (raidz, raidz2, raidz3)

-groups                RAID groups per stripe quantity

-disks                   Disks per RAID group quantity

-size                      Disk size (example: 1000GB, 2TB, 512MB)

 

 

 

example usage:

 

 

show_me_my_zfs.pl -raid=raidz2 -groups=4 -disks=12 -size=14000GB

 

=cut

 

 

 

 

use warnings;

use strict;

use Getopt::Long;

use Data::Dumper qw(Dumper);

 

my $logfile="/root/zfs_calc/scripts/log.log";

my $initial_pool_name="big_pool_initial";

my $zvol_dir="/dev/zvol/dsk/$initial_pool_name/";

my $pool_name="test_pool";

my ($type, $groups, $disks, $size);

 

GetOptions('raid|r=s' => \$type,

           'groups|g=s' => \$groups,

           'disks|d=s' => \$disks,

           'size|s=s' => \$size);

 

 

my $disk_count = $groups * $disks;

 

system("zpool destroy big_pool_initial 2>/dev/null");

system("rm /root/zfs_calc/disks/big_pool_initial.dsk 2>/dev/null");

system("truncate -s 4E /root/zfs_calc/disks/big_pool_initial.dsk");

system("zpool create big_pool_initial /root/zfs_calc/disks/big_pool_initial.dsk");

system("zfs set compression=lz4 big_pool_initial");

 

# create zvol's ("pseudo-disks")

my $phrase = "zpool create $pool_name ";

for (my $i = 1; $i <= $disk_count; $i++) {

  if (($i-1+$disks) % $disks == 0) {

     $phrase .= "$type ";

  }

  my $disk_name = "disk_" . sprintf("%05d", $i);

  system("zfs create -V $size $initial_pool_name/$disk_name");

  $phrase .= $zvol_dir . $disk_name . " ";

}

 

# create zpool from pseudo-disks

print "# " . $phrase . "\n";

system("$phrase");

 

 

# create dataset from early created zpool

system("zfs create $pool_name/test_dataset");

print "\n------------------------------------------------------------\n";

# show zpool list

print "# zpool list $pool_name\n";

system("zpool list $pool_name");

print "\n------------------------------------------------------------\n";

# show zpool status -v

print "# zpool status -v $pool_name\n";

system("zpool status -v $pool_name");

print "\n------------------------------------------------------------\n";

# show zfs list

print "# zfs list -r $pool_name\n";

system("zfs list -r $pool_name");

print "\n------------------------------------------------------------\n";

 

# destroy pool from pseudo-disks

system("zpool destroy $pool_name");

 

# destroy pseudo-disks

#

for (my $i = 1; $i <= $disk_count; $i++) {

  my $disk_name = "disk_" . sprintf("%05d", $i);

  my $cmd = "zfs destroy $initial_pool_name\/$disk_name";

  system("$cmd");

}

 

system("zpool destroy big_pool_initial 2>/dev/null");

system("rm /root/zfs_calc/disks/big_pool_initial.dsk 2>/dev/null");
