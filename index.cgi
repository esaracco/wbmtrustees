#!/usr/bin/perl

# Copyright (C) 2003-2004
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
&ReadParse ();

my $help = $text{"trustees_help"};

&header($text{'trustees_title_index'}, "", "index", 1, 1, 0, undef, undef, undef, "<a href=\"http://wbmtranslator.labs.libre-entreprise.org/index.html\" target=\"_BLANK\">$text{'PROJECT_HOMEPAGE'}</a>&nbsp;|&nbsp;<a href=\"http://labs.libre-entreprise.org/project/showfiles.php?group_id=36\" target=\"_BLANK\">$text{'DOWNLOAD'}</a>&nbsp;|&nbsp;<a href=\"http://webmin.mamemu.de/devel.html\" target=\"_BLANK\">$text{'LATEST_TRUSTEES'}</a>");
print "<hr>\n";

# Check trustee config/installation, exit if incorrect
$err = &trustees_check_install();
if ($err) {
	print "<p><b>$err</b><p>\n";
	print "<hr>\n";

	&footer("/", $text{'index'});
	exit;
}

print <<EOF;
<form action="add_trustee.cgi">
<table border=0 cellpadding=2 cellspacing=2 align="center">
<tr $tb><th colspan="3">$text{'trustees_text_add_path'}</th></tr>
<tr $cb>
<td><input type="text" name="what" value="">
EOF

print &file_chooser_button('what', 0, 0);

print <<EOF;
</td>
<td><input type="submit" value="$text{'trustees_button_add'}"></td>
</tr>
EOF

print "<tr $cb><td colspan=\"3\">" . &hlink ($help, 'index_add') . "</td></tr>\n";

print <<EOF;
</table>
</form>

<center>
<form action=apply_trustees.cgi>
<input type=submit value="$text{'trustees_restart'}">
</form>
</center>

<table border=0 cellpadding=2 cellspacing=2 align="center" width="100%">
EOF

print 
	"<tr $tb><td>" .
	"<b>$text{'trustees_table_title_path'}</b> " .
	&hlink ($help, 'index_list') .
	"</td><td colspan=\"2\"><b>Action</b> " . 
	&hlink ($help, 'index_action') . 
	"</td></tr>";


&trustees_display_list ();

print "</table>\n";

&footer("/", $text{'index'});
