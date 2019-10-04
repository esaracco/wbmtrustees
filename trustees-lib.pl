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

do '../web-lib.pl';
&init_config();

# trustees rights
use constant @rights = ('R', 'W', 'B', 'E', 'X', 'U');
# trustees rights modificators
use constant @modificators = ('C', 'D', '!', 'O');

# type section of the mount output
use constant %mount_types = (
	# local filesystems
	'ext2' => 'local',
	'ext3' => 'local',
	'reiserfs' => 'local',
	'vfat' => 'local',
	'ntfs' => 'local',
	'iso9660' => 'local',
	# network filesystems
	'smbfs' => 'network',
	'nfs' => 'network',
	# rejected types
	'proc' => 'rejected',
	'devpts' => 'rejected'
);

# mount command system output
# DEBUG my @mount_output = `/bin/mount_trustees`;
my @mount_output = `/bin/mount`;
# partition => path (from mount output)
my %device_path = ();
# partition => type (from mount output)
my %device_type = ();

# system groups, order by name
my @system_groups = ();
# system users, order by name
my @system_users = ();

# trustees_check_install ()
# IN: -
# OUT: A error message or nothing if all is ok
# 
# Check trustees config/installation
# 
sub trustees_check_install ()
{
	if ((!-x $config{'trustees_cmd'}) ) 
	{
		return $text{'trustees_error_cmd'};
	} 
	elsif (!-r $config{'trustees_conf'}) 
	{
		return $text{'trustees_error_conf'};
	} 
	elsif (!-r $config{'trustees_error_syscall'}) 
	{
		return $text{'syscall_err'};
	}
}

# trustees_acl_already_exist ( $ $ )
# IN: The group or user to check for, entire trustees line
# OUT: 1 if acl already exist, 0 otherwise
#
# Check if the given acl is already present in a given trustees
# line
# 
sub trustees_acl_already_exist ( $ $ )
{
	my ($owner, $line) = @_;
	my $regowner = quotemeta ($owner);

	return ($line =~ /\:$regowner\:/);
}

# trustees_path_already_exist ( $ )
# IN: Device, The path to check for
# OUT: 1 if path already exist, 0 otherwise
#
# Check if the given path is already present in the trustees
# configuration file
# 
sub trustees_path_already_exist ( $ $ )
{
	my ($device, $path) = @_;
	my $regpath = quotemeta ($path);
	my $regdevice = quotemeta ($device);
	my $buffer = '';

	open (CONF, $config{'trustees_conf'});
	$buffer = join (' ', <CONF>);
	close (CONF);

	return ($buffer =~ /$device[\]\}]$regpath\:/);
}

# trustees_display_list ()
# IN: -
# OUT: -
# 
# Print HTML code to show existing trustees
# 
sub trustees_display_list () 
{
	my $url = '';
	my $without_device = '';
	my $trustee = '';
	my $activate_deactivate = '';
	my $edit_unedit = '';
  
	open(CONF, $config{'trustees_conf'});
	while(<CONF>) {
		my $active = 0;
		my $trustees_cb = " bgcolor=\"gray\"";
		my $delete_add = 'delete';
		
		next if /^$/;

		chomp ();

		if (/^#[\[\{].*/)
		{
			$activate_deactivate = 
				$text{'trustees_button_activate'};
			$delete_add = 'add';
			$_ =~ s/^#//;
		}
		elsif (/#.*/)
		{
			next;
		}
		else
		{
			$active = 1;
			$trustees_cb = $cb;
			$activate_deactivate = 
				$text{'trustees_button_deactivate'};
		}

		# just get the first part of the line (device + path)
		# TODO -> do a function for that
		@tmp = split (/:/, $_);
		$trustee = (/^\{/) ? "$tmp[0]\:$tmp[1]" : $tmp[0];
	
		$without_device = &trustees_skip_device ($trustee);
		$complete_path = 
			&trustees_get_complete_path ($trustee);
			
		$url = "active=$active&what=" . &urlize ($trustee);

		$edit_unedit = ($active) ?
			 "<a href=\"edit_trustee.cgi?$url\">" .
			 "$complete_path</a>" :
			 $complete_path;

print <<EOF;
<tr>
<td $trustees_cb>$edit_unedit</td>
<td $trustees_cb width="5" align="center"><a href=\"$delete_add\_trustee.cgi?virtual=1&$url\">$activate_deactivate</a></td><td $trustees_cb width="5"><a href=\"delete_trustee.cgi?virtual=0&$url\">$text{'trustees_button_delete'}</a></td>
</tr>
EOF
	}
	close CONF;
}

# trustees_get_modificator ( $ $ )
# IN: The rights string, the right to return the modificator for
# OUT: The modificator or a empty string
#
# If it exist, return the modificator for a given right
# 
sub trustees_get_modificator ( $ $ )
{
	my ($rights, $right) = @_;
	my $modificators_str = join ("", @modificators);
	
	for ($i = 0; $i < length ($rights); $i++)
	{
		if (substr ($rights, $i, 1) eq $right)
		{
			my $modificator = '';
			
			if ($i)
			{
				$modificator = substr ($rights, $i - 1, 1);
				return $modificator 
					if $modificators_str =~ /$modificator/;
			}

			return '';
		}
	}

	return '';
}

# trustees_get_rights_panel ( $ )
# IN: Prefix for naming form variables, 
#     String containing trustees rights (ex: R!WEBX)
# OUT: A buffer with HTML code of the panel
#
# Fill a buffer with the HTML code to display a rights panel
# 
sub trustees_get_rights_panel ( $ $ )
{
	my ($prefix, $selected) = @_;
	my $buffer = '';
	my $i = 0;

	$buffer = "<table border=0 cellpadding=2 cellspacing=2><tr>\n";
	foreach (@rights)
	{
		$buffer .= 
			"<td " . (($selected =~ /$_/) ? 
				'bgcolor="gray"' : 
				"$cb") . 
			"><font size=2><b>$_</b></font></td>" .
			"<td $cb>" . &trustees_get_combo_modificators (
			"$prefix\_modificator_$i", 
			&trustees_get_modificator ($selected, $_)) . 
			"</td><td $cb>" .
			"<input title=\"$_\: " .
			$text{"trustees_item_title_$_"} . 
			"\" type=\"checkbox\" name=\"$prefix\_right_$i\"" .
			(($selected =~ /$_/) ? ' CHECKED' : '') . 
			" value=\"$_\">" .
			"</td>";
			$i++;
	}
	$buffer .= "</tr></table>\n";
	
}

# trustees_get_combo_modificators ( $ )
# IN: Prefix for naming form variables,
#     Modificator to select by default
# OUT: A buffer with HTML code of the combo
#
# Fill a buffer with the HTML code to display a combo of trustees 
# rights modificators
# 
sub trustees_get_combo_modificators ( $ $ )
{
	my ($prefix, $selected) = @_;
	my $buffer = '';

	$buffer = "<select title=\"\" name=\"$prefix\">\n";
	$buffer .= 
		"<option value=\"\">$text{'trustees_select_none'}</option>\n";
		
	foreach (@modificators)
	{
		$buffer .= 
			sprintf ("<option title=\"$_\: " .
			$text{"trustees_item_title_$_"} .
			"\" value=\"%s\"%s>%s</option>\n", 
				$_, ($selected eq $_) ? ' SELECTED' : '', $_);
	}
	$buffer .= "</select>\n";
	
	return $buffer;
}

# trustees_init_system_groups ()
# IN: -
# OUT: -
#
# Initialize the @system_groups array with system groups
# alphabetically sorted
# 
sub trustees_init_system_groups ()
{
	open (H, "cat /etc/group \| cut -d\: -f1 |");
	foreach (<H>)
	{
		chomp ();
		push @system_groups, $_;
	}
	close (H);
	
	@system_groups = sort @system_groups;
}

# trustees_init_system_users ()
# IN: -
# OUT: -
#
# Initialize the @system_users array with system users
# alphabetically sorted
# 
sub trustees_init_system_users ()
{
	open (H, "cat /etc/passwd \| cut -d\: -f1 |");
	foreach (<H>)
	{
		chomp ();
		push @system_users, $_;
	}
	close (H);
	
	@system_users = sort @system_users;
}

# trustees_get_combo_users ( $ $ )
# IN: Prefix for naming form variables, Selected item
# OUT: HTML code of the combo box
#
# Build a combo of the stsyem users and retrun its HTML code
# 
sub trustees_get_combo_users ( $ $ )
{
	my ($prefix, $selected) = @_;
	my $buffer = '';

	&trustees_init_system_users () if not @system_users;

	$buffer = "<select name=\"$prefix\_user\">\n";
	$buffer .= 
		"<option value=\"\">$text{'trustees_select_user'}</option>\n" .
		"<option value=\"*\"" .
		(($selected eq '*') ? ' SELECTED' : '') .
		">$text{'trustees_select_all_users'}</option>\n";
		
	foreach (@system_users)
	{
		$buffer .= 
			sprintf ("<option value=\"%s\"%s>%s</option>\n", 
				$_, ($selected eq $_) ? ' SELECTED' : '', $_);
	}
	$buffer .= "</select>\n";
	
	return $buffer;
}

# trustees_get_combo_groups( $ $ )
# IN: Prefix for naming form variables,, Selected item
# OUT: HTML code of the combo box
#
# Build a combo of the stsyem groups and retrun its HTML code
# 
sub trustees_get_combo_groups ( $ $ )
{
	my ($prefix, $selected) = @_;
	my $buffer = '';

	&trustees_init_system_groups () if not @system_groups;
	
	$buffer = "<select name=\"$prefix\_group\">\n";
	$buffer .= 
		"<option value=\"\">$text{'trustees_select_group'}</option>\n";

	foreach (@system_groups)
	{
		$buffer .= 
			sprintf ("<option value=\"%s\"%s>%s</option>\n",
				$_, ($selected eq $_) ? ' SELECTED' : '', $_);
	}
	$buffer .= "</select>\n";
	
	return $buffer;
}

# trustees_skip_device ( $ )
# IN: A trustees line
# OUT: The given string minus device specification.
# 
# Remove device or network part.
# Example:
# 	[/dev/hdb1]/samba/shares/disk_g/ -> /samba/shares/disk_g/
# 	
sub trustees_skip_device ( $ )
{
	my $trustee = shift;
	
	$trustee =~ s/^\[.*\]//;
	$trustee =~ s/^\{.*\}//;
	
	return $trustee;
}

# trustees_get_device_from_string ( $ )
# IN: A trustees line
# OUT: The device specified in the string
# 
# Return the device specified on the given string
# 	
sub trustees_get_device_from_string ( $ )
{
	my $trustee = shift;

	$trustee =~ s/[\]\}].*//;
	$trustee =~ s/^[\[\{]//;
	
	return $trustee;
}


# trustees_acl_error_if_not_valid( $ $ $ $)
# IN: ACL number (its order in the form),
#     group, user, rights
# OUT: -
#
# Check if a given ACL is valid. This function display appropriate errors
# and end the page display if ACL is not valid
# 
sub trustees_acl_error_if_not_valid ( $ $ $ $)
{
        my ($acl_nbr, $group, $user, $rights) = @_;
        my $prefix = "[ACL $acl_nbr] ";
         
	#user must choose a owner
        &error ($prefix . $text{'trustees_error_choose_owner'})
		if (not $group and not $user);
                                                                                
	#owner must be a group OR a user, not both
        &error ($prefix . $text{'trustees_error_choose_group_or_user'})
		if ($group and $user);
                                                                                
	#user must indicate a least 1 right
        &error ($prefix . $text{'trustees_error_choose_rights'}) 
		if not $rights;
}

# trustees_add_acl_tmp ( $ $ $ )
# IN: A trustees line, owner to add, rights to add for the given owner
# OUT: The same trustees line plus new owner:rights
# 
# Add a ACL in the given trustees line
# 
sub trustees_add_acl_tmp ( $ $ $ ) 
{
	my ($trustee, $owner, $rights) = @_;

	$trustee .= ($trustee =~ /:$/) ? 
		$owner . ':' . $rights :
		':' . $owner . ':' . $rights;

	return $trustee;
}

# trustees_delete_acl_tmp ( $ $ $ )
# IN: A trustees line, owner to delete, rights to delete for the given owner
# OUT: The same trustees line minus given owner:rights
# 
# Delete a ACL in the given trustees line
#
sub trustees_delete_acl_tmp ( $ $ $ ) 
{
	my ($trustee, $owner, $rights) = @_;
	my $regdelete1 = quotemeta ($owner) . ':' . quotemeta ($rights) . ':';
	my $regdelete2 = quotemeta ($owner) . ':' . quotemeta ($rights) . '$';
	
	$trustee =~ s/$regdelete1//;
	$trustee =~ s/$regdelete2//;
	$trustee .= ':' if ($trustee !~ /:$/);

	return $trustee;
}

# trustees_add_virtual ( $ )
# IN: First path of a existent trustees line
# OUT: -
#
# Decomment a line in trustees configuration file
# 
sub trustees_add_virtual ( $ )
{
	my $trustee = shift;
	my $regtrustee = quotemeta("$trustee\:");
	my $old_file = $config {'trustees_conf'};
	my $new_file = "$old_file.tmp.$$";
	
	&lock_file ($new_file);
	open (OLD, "< $old_file");
	open (NEW, "> $new_file");
	while(<OLD>) 
	{
		s/^#// if (/$regtrustee/);
		print NEW;
	}
	close OLD;
	close NEW;
	&unlock_file ($new_file);

	unlink ($old_file);
	rename ($new_file, $old_file);
}

# trustees_add ( $ $ )
# IN: Line to add or decomment
# OUT: -
#
# Add a trustees line in the configuration file
# 
sub trustees_add ( $ )
{
	my $trustee = shift;

	&lock_file ($config {'trustees_conf'});
	open H, ">>" . $config {'trustees_conf'};
	print H "$trustee\n";
	&unlock_file ($config {'trustees_conf'});
	close (H);
}

# trustees_update ( $ $ )
# IN: First part of a trustees line (device + path), whole trustees line
# OUT: - 
# 
# Update a trustees line in the configuration file
#
sub trustees_update ( $ $ ) 
{
	my ($trustee, $trustee_all) = @_;
	my $regtrustee = quotemeta("$trustee\:");
	my $old_file = $config {'trustees_conf'};
	my $new_file = "$old_file.tmp.$$";

	$trustee_all .= ':' if ($trustee_all !~ /:/);

	&lock_file ($new_file);
	open (OLD, "< $old_file");
	open (NEW, "> $new_file");
	while(<OLD>) 
	{
		print NEW (/$regtrustee/) ? "$trustee_all\n" : $_;
	}
	close OLD;
	close NEW;
	&unlock_file ($new_file);

	unlink ($old_file);
	rename ($new_file, $old_file);
}

# trustees_delete ( $ $ )
# IN: First part of a trustees line (device + path), 
#     1 (virtual deletion (line comments)) or 0 (real deletion)
# OUT: -
# 
# Delete or comment a trustees line in the configuration file 
# 
sub trustees_delete ( $ $ ) 
{
	my ($trustee, $virtual) = @_;
	my $regtrustee = quotemeta("$trustee\:");
	my $old_file = $config {'trustees_conf'};
	my $new_file = "$old_file.tmp.$$";
	
	&lock_file ($new_file);
	open (OLD, "< $old_file");
	open (NEW, "> $new_file");
	while(<OLD>) 
	{
		if ($virtual)
		{
			 $_ = '#' . $_ if (/$regtrustee/);
		}
		else
		{
			next if (/$regtrustee/);
		}
		print NEW;
	}
	close OLD;
	close NEW;
	&unlock_file ($new_file);

	unlink ($old_file);
	rename ($new_file, $old_file);
}

# trustees_get_whole_line ( $ )
# IN: First part of a trustees line (device + path)
# OUT: The whole corresponding line in the trustees configuration file
#
# Return a whole trustees line
# 
sub trustees_get_whole_line ( $ )
{
	my $trustee  = shift;
	my $regtrustee = quotemeta("$trustee\:");
	my $all = '';

	open(CONF, $config{'trustees_conf'});
	while(!$all && ($_ = <CONF>)) 
	{
		$all = $_ if (/$regtrustee/);
	}
	close CONF;

	if ($all)
	{
		chomp ($all);
	}
	else
	{
		$all = $trustee;
	}

	return $all;
}

# trustees_get_acls_from_string ( $ )
# IN: A trustees line
# OUT: The ACLs part of the given string
#
# Return the ACLs part of a given trustees line
# 
sub trustees_get_acls_from_string ( $ )
{
	my $trustee  = shift;

	$trustee =~ s/^\[.*\][^:]*://;
	$trustee =~ s/^\{.*\}[^:]*://;

	return $trustee;
}

# trustees_get_acls_from_file ( $ )
# IN: First part of a trustees line (device + path)
# OUT: The ACLs of the given path
# 
# Return the ACLs for the given path
# 
sub trustees_get_acls_from_file ( $ ) 
{
	my $trustee = shift;
	my $regtrustee = quotemeta("$trustee\:");
	my $acls = '';
	
	open(CONF, $config{'trustees_conf'});
	while(!$acls && ($_ = <CONF>)) {
		if (/$regtrustee/)
		{
			s/^\[.*\][^:]*://;
			s/^\{.*\}[^:]*://;
			$acls = $_;
		}
	}
	close CONF;

	chomp ($acls);
	return $acls;
}

# trustees_get_device ( $ )
# IN: A system path (directory with or without file)
# OUT: The system device for the given path
# 
# Return the system device for a given path, using the mount system command
# 
sub trustees_get_device ( $ )
{
	my $path = shift;

	&trustees_init_devices_paths () if not %device_path;
  
	foreach my $key (
		sort trustees_device_path_hash_sort (keys (%device_path)))
	{
		return $key if ($path =~ /^$device_path{$key}/);
	}
                                                                                
	return '';
}

# trustees_get_complete_path ( $ )
# IN: String with mount point + path
# OUT: String with the absolute path on the system
#
# Rebuild the complete path for a given path, completed with
# the partition mount point
# 
sub trustees_get_complete_path ( $ )
{
	my $trustee = shift;
	my $device = &trustees_get_device_from_string ($trustee);
	my $just_path = &trustees_skip_device ($trustee);
	my $prefix = '';

	&trustees_init_devices_paths () if not %device_path;
	$prefix = $device_path{$device};

	$prefix =~ s/\/$//;
	$just_path =~ s/^\///;
	return "$prefix/$just_path";
}

# trustees_rewrite_path ( $ $ )
# IN: Device for the path, path to rewrite
# OUT: The entire path (relative to the mount point path)
#
# Rewrite the given path according to the mount point
# path
# 
sub trustees_rewrite_path ( $ $ )
{
	my ($device, $path) = @_;
	my $regpath = quotemeta ($path);
	my $type = '';

	return '' if not ($type = &trustees_get_type ($device));

	foreach my $key (
		sort trustees_device_path_hash_sort (keys (%device_path)))
	{
		my $regsystempath = quotemeta ($device_path{$key});

		if ($path =~ /^$regsystempath/)
		{
			$path =~ s/^$regsystempath//;
			$path = '/' . $path if $path !~ /^\//;

			return $path;
		}
	}

	return '';
}

# trustees_get_type ( $ )
# IN: A system device
# OUT:
#
# Return the "type" of a given device. Return value can be empty,
# so caller must check it and return a error.
# 
sub trustees_get_type ( $ )
{
	my $device = shift;

	&trustees_init_devices_types () if not %device_type;

	foreach my $key (keys (%device_type))
	{
		if ($key eq $device)
		{
			my $type = $device_type{$key};
			my $n_l = $mount_types{$type};

			return $n_l;
		}
	}

	return '';
}

# trustees_device_path_hash_sort ($ $)
# IN: Values to compare 
# OUT: True if first value < second value, false otherwise
# 
# Sort the device_path array by length
# 
sub trustees_device_path_hash_sort ($ $)
{
	my ($a, $b) = @_;
	length ($device_path{$b}) <=> length ($device_path{$a});
}

# trustees_init_devices_paths ()
# IN: -
# OUT: -
# 
# Fill the global hash device with mount output
# 
sub trustees_init_devices_paths ()
{
	return if %device_path;

	%device_path = ();
	foreach (@mount_output)
	{
		my @line = split / /;
		$device_path{$line[0]} = $line[2];
	}
}

# trustees_init_devices_types ()
# IN: -
# OUT: -
# 
# Fill the global hash devices types with mount output
# 
sub trustees_init_devices_types ()
{
	return if %device_type;

	%device_paths = ();
	foreach (@mount_output)
	{
		my @line = split / /;
		$device_type{$line[0]} = $line[4];
	}
}
1;
