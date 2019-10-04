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

my $trustee = $in{'what'};
my $trustee_all = $in{'trustee_all'};
my $group = $in{'add_group'};
my $user = $in{'add_user'};
my $rights = '';
my $i = 0;

# user must choose a owner
&error ($text{'trustees_error_choose_owner'}) if (not $group and not $user);

# owner must be a group OR a user, not both
&error ($text{'trustees_error_choose_group_or_user'}) if ($group and $user);

# build the access rights part
for ($i = 0; $i < 7; $i++)
{
	my $right = $in{"add_right_$i"};
	my $modificator = $in{"add_modificator_$i"};
	
	$rights .= (($modificator) ? $modificator : '') . $right if ($right);
}

# user must indicate a least 1 right
&error ($text{'trustees_error_choose_rights'}) if not $rights;

# build the owner part
$owner = ($group) ? "+$group" : $user;

# check if the ACL already exist
&error ($text{'trustees_error_acl_already_exist'})
	if &trustees_acl_already_exist ($owner, $trustee_all);

# add new ACL
$trustee_all= &trustees_add_acl_tmp ($trustee_all, $owner, $rights);

&redirect("edit_trustee.cgi?what=" . urlize ($trustee) . "&trustee_all=" . &urlize ($trustee_all));
