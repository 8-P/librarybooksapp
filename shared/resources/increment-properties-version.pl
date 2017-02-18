#!/opt/local/bin/perl
# =============================================================================
#
# Increment the properties list version number.
#
# =============================================================================

use strict;
use warnings;

use Mac::PropertyList qw(:all);
use Readonly;
use File::Compare;
use Data::Dumper;

# Constants -------------------------------------------------------------------

Readonly::Scalar my $CURR_PROPERTIES_FILE	=> 'LibraryProperties.plist';
Readonly::Scalar my $LAST_PROPERTIES_FILE	=> 'LibraryPropertiesLast.plist';
Readonly::Scalar my $VERSION_FILE			=> 'LibraryPropertiesVersion.plist';

# -----------------------------------------------------------------------------

sub
main
{
	my $data	= parse_plist_file($VERSION_FILE);
	my $version	= $data->value('LibraryPropertiesVersion');

	# See if the properties file has been updated
	if (compare($CURR_PROPERTIES_FILE, $LAST_PROPERTIES_FILE) == 0)
	{
		warn "No update needed, currently at version [$version]\n";
		exit 0;
	}
	else
	{
		$version++;
		#warn "Incrementing version to [$version]\n";
	}
	
	# Update versions file
	my %hash =
	(
		LibraryPropertiesVersion => $version,
	);
	my $plist = create_from_hash(\%hash);
	open FILE, ">$VERSION_FILE";
	print FILE $plist;
	close FILE;
	
	# Update last file
	system("cp $CURR_PROPERTIES_FILE $LAST_PROPERTIES_FILE");

	# Formatted to appear in Xcode	
	warn "warning: [$VERSION_FILE] updated, incremented to version [$version]\n";
}

# -----------------------------------------------------------------------------

main();
# vim:ts=4:sw=4
