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
my $owner = $in{'owner'};
my $rights = $in{'rights'};

$trustee_all= &trustees_delete_acl_tmp ($trustee_all, $owner, $rights);

&redirect("edit_trustee.cgi?what=" . urlize ($trustee) . "&trustee_all=" . &urlize ($trustee_all));
