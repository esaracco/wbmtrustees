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

my $help = $text{'trustees_help'};
my $i = 0;
my $j = 0;
my $k = 0;
my $trustee = $in{'what'};
my $trustee_all = $in{'trustee_all'};
my $without_device = &trustees_skip_device("$trustee");
my @acls = ();

&header($text{'trustees_title_edit'}, '', 'edit');

print "<center><font size=+2>" . sprintf ($text{'trustees_subtitle_edit'}, $without_device) . "</font></center>";

# if the configuration line has not yet been cached in
# a string, cache it for the futur operations
if (!$trustee_all)
{
	$trustee_all = &trustees_get_whole_line ($trustee);
	@acls = split(/:/, &trustees_get_acls_from_file ($trustee));
}

# if configuration line has been cached, use it instead of reading
# physically the trustees configuration file
elsif ($trustee_all ne $trustee)
{
	@acls = split(/:/, &trustees_get_acls_from_string ($trustee_all));
}

my $combo_groups = &trustees_get_combo_groups ('add', '');
my $combo_users = &trustees_get_combo_users ('add', '');
my $rights_panel = &trustees_get_rights_panel ('add', '');

print <<EOF;
<hr>

<form action="add_trustee_acl.cgi" method="POST">
<input type="hidden" name="trustee_all" value="$trustee_all">
<input type="hidden" name="what" value="$trustee">
<table border=0 cellpadding=2 cellspacing=2 align="center">
EOF

print
	"<tr $tb><td><b>$text{'trustees_table_title_owner'}</b> " .
	&hlink ($help, 'edit_owner') . "</td><td>" .
	"<b>$text{'trustees_table_title_rights'}</b> " .
	&hlink ($help, 'edit_rights') . "</td></tr>";

print <<EOF;
<tr>
<td $cb align="center">$combo_groups<br>$combo_users</td>
<td $cb align="center">$rights_panel</td>
</tr>
<tr><td $cb align="center" colspan="3"><input type="submit" value="$text{'trustees_button_add'}"></td></tr>
</table>
</form>

<form action="save_trustee.cgi" method="POST">
<hr>
<input type="hidden" name="trustee_all" value="$trustee_all">
<input type="hidden" name="trustee" value="$trustee">
<table border=0 cellpadding=2 cellspacing=2 width="100%">
<tr $tb><td><b>$text{'trustees_table_title_owner'}</b></td><td><b>$text{'trustees_table_title_rights'}</b></td><td><b>$text{'trustees_table_title_action'}</b></td></tr>
EOF

# list the ACLs of the current path in edition
while ($acls[$i]) 
{
	my $owner = '';
	my $rights = '';
	my $combo_groups = '';
	my $combo_users = '';
	my $owner_group = '';
	my $owner_user = '';
	my $rights_panel = '';
	
	$owner = $acls[$i++];
	$k = $i;
	$rights = $acls[$i++];

	# owner can be a user or a group. if it is a group,
	# add a "+" signe before (see trustees specifications)
	if ($owner =~ /^\+/)
	{
		$owner_group = $owner;
		$owner_group =~ s/^\+//;
	}
	else
	{
		$owner_user = $owner;
	}
	$combo_groups = &trustees_get_combo_groups ($j, $owner_group);
	$combo_users = &trustees_get_combo_users ($j, $owner_user);
	$url = 
		"what=" . &urlize ($trustee) . 
		"&trustee_all=" .&urlize ($trustee_all) .
		"&owner=" . &urlize ($owner) .
		"&rights=" . &urlize ($rights);

	# get check buttons and combo boxes for rights
	# management of the current printed ACL
	$rights_panel = &trustees_get_rights_panel ("$j\_update", $rights);

print <<EOF;
<tr>
<td $cb align="center">$combo_groups<br>$combo_users</td>
<td $cb align="center">$rights_panel</td>
<td $cb align="center"><input type="button" name="" value="$text{'trustees_button_delete'}" 
onCLick=\"location.href='delete_trustee_acl.cgi?$url'\"></td>
</tr>
EOF

	$j++;
}

print <<EOF;
<tr $cb><td align="center" colspan="3"><input type="submit" value="$text{'trustees_button_save'}"></td></tr>
</table>
</form>
<hr>
EOF

&footer("", $text{'trustees_return_index_module'});

