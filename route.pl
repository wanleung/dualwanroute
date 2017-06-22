#!/usr/bin/perl

#
#    dualwanroute - A small tool on setting dual wan route table.
#    Copyright (C) 2017  Wan Leung Wong - me [at] wanleung [dot] com
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;
use warnings;
#use Data::Dumper;

my $wan_1_name = 'pccw';
my $wan_2_name = 'hkbn';
my $wan_1_inet = 'p2p1';
my $wan_2_inet = 'enxf01e34000d76';

my @use_wan_1_network = ('10.1.0.0/16');
my @use_wan_2_network = ('10.10.0.0/16');

sub read_dhcp {
    my ($inet) = @_;
    my $dhcp_file = '/var/lib/dhcp/dhclient.'.$inet.'.leases';
    if ( -e $dhcp_file ) {
        open FILEIN, '<'.$dhcp_file;

        my $interface;
        my $fixed_address;
        my $gateway;
        while (my $line = <FILEIN>) {
            if ($line =~ /interface "(.*)";/) {
                $interface = $1;
            }
            elsif ($line =~ /fixed-address (.*);/) {
                $fixed_address = $1;
            }
            elsif ($line =~ /option routers (.*);/) {
                $gateway = $1;
            }
        }
        close FILEIN;
        my @result = ($interface, $fixed_address, $gateway);
        return \@result;
    }
}

sub add_route {
    my ($wan_name, $wan_inet, $use_wan_network, $data) = @_;

    system("ip route add default via $data->{$wan_inet}->[2] dev $wan_inet table $wan_name");
    for my $net (@$use_wan_network) {
        system("ip rule add from $net table $wan_name");
    }

}

sub main {
    my $out = `ip address show | grep inet| grep global`;
    my @inets = split /\n/, $out;

    my $inet_hash = {};

    for my $inet (@inets) {
        my @param = split /\s+/, $inet;
        my @data = ($param[2],$param[4]);
        $inet_hash->{$param[7]} = read_dhcp($param[7]);
    }

    add_route($wan_1_name, $wan_1_inet, \@use_wan_1_network, $inet_hash);
    add_route($wan_2_name, $wan_2_inet, \@use_wan_2_network, $inet_hash);
}

main();
