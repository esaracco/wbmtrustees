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

my @separators = ('[', ']');
my $path = '';
my $path_rewrited = '';
my $device = '';
my $type = '';

$path = $in{'what'};
$virtual = $in{'virtual'};

# retrieve the system device and type of the given path
if ($device = &trustees_get_device ($path))
{
	# type can be 'local', 'network' or 'rejected'
	$type = &trustees_get_type ($device);
	
	# type can be 'local' or 'network'
	@separators = ('{', '}') if ($type eq 'network');

	# rewrite path regarding to the mount point on
	# the system
	$path_rewrited = &trustees_rewrite_path ($device, $path);
}

# if we just add in a string, not directly in the
# configuration file
if ($virtual)
{
	&trustees_add_virtual ($path);
}

# if the format is incorrect
elsif (
	(not $path) or 
	($path !~ /^\//) or
	(not -e $path) or
	(not $device)
  )
{
	&error ($text {'trustees_error_bad_path'} . ": \"$path\"");
}

# if the path to add already exist in the configuration
# file
elsif (&trustees_path_already_exist ($device, $path_rewrited))
{
	&error ($text {'trustees_error_path_already_exist'} . ": \"$path\"");
}

# all is ok: insert the new path
else
{
	&error ($text{'trustees_error_type_unknown'}) if not $type;
	&error ($text{'trustees_error_type_rejected'} . ": \"$path\"") 
		if $type eq 'rejected';
	
	&trustees_add (
		$separators[0] . $device . $separators[1] . 
			$path_rewrited . ':');
}

&redirect ("");
