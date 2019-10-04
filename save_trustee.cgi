#!/usr/bin/perl

# Copyright (C) 2003
# Emmanuel Saracco <esaracco@users.labs.libre-entreprise.org>
# Easter-eggs <http://www.easter-eggs.com>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330,
# Boston, MA 02111-1307, USA.

require './trustees-lib.pl';
&ReadParse();

my $i = 0;
my $trustee = $in{'trustee'};
my $trustee_all = $in{'trustee_all'};
my @acls = split(/:/, &trustees_get_acls_from_string ($trustee_all));;
my $acls_count = (scalar (@acls)) ? scalar (@acls) / 2 : 0;

# build all trustees ACLs for the path being
# edited
$trustee_all = $trustee;
for ($i = 0; $i < $acls_count; $i++)
{
	my $rights = '';
	my $owner = '';
	my $group =  $in{"$i\_group"};
	my  $user = $in{"$i\_user"};
	
	$j = 0;
	for ($j = 0; $j < 7; $j++)
	{
	        my $right = $in{"$i\_update_right_$j"};
	        my $modificator = $in{"$i\_update_modificator_$j"};
	        
		$rights .= (($modificator) ? $modificator : '') . $right 
			if ($right);
	}

	# display a error if builded ACL is not valid
	&trustees_acl_error_if_not_valid ($i + 1, $group, $user, $rights);	

	$owner = (($group) ? "+$group" : $user);
	
	# check if there is already a ACL for this owner
	&error ("[ACL $i] " . $text{'trustees_error_acl_already_exist'}) 
		if &trustees_acl_already_exist ($owner, $trustee_all);
	
	$trustee_all .= ":$owner\:$rights";
}

# save line in the trustees configuration file
&trustees_update ($trustee, $trustee_all);
&redirect("");
