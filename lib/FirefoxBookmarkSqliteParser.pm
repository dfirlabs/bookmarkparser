# Copyright 2023 Google LLC
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     https://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# FirefoxBookmarkSqliteParser.pm
#
# Firefox implementation of bookmark parsing.

use strict;
use warnings;

package FirefoxBookmarkSqliteParser;

use parent 'FirefoxBookmarkParserBase';

use DateTime;
use DBI;
use JSON;


my $CANHANDLE_QUERY = "SELECT count(*) as count FROM sqlite_master WHERE type='table' AND name in ('moz_places', 'moz_bookmarks')";
my $DIRECTORY_QUERY = "select id, parent, title, dateAdded, lastModified, guid from moz_bookmarks where type=2 order by parent";
my $LINK_QUERY = "select mb.id, mb.parent, mb.title, mb.dateAdded, mb.lastModified, mp.url as uri, mp.visit_count, COALESCE(mp.last_visit_date, 0) as last_visit_date from moz_bookmarks mb left join moz_places mp on mb.fk=mp.id where mb.type=1";


sub CanHandle{
	# Returns 1 if this parser can handle the data parssed in {data => "bookmark data"}, 0 otherwise.
	my ($args) = @_;

	my $filename = $args->{'filename'};
	my $count = 0;

	eval {
		my $dbh = DBI->connect("DBI:SQLite:dbname=$filename", '', '', {RaiseError => 1}) || die $DBI::errstr;
		my $stmt = $dbh->prepare($CANHANDLE_QUERY) || die $DBI::errstr;
		$stmt->execute() || die $DBI::errstr;
		my $row = $stmt->fetchrow_hashref();
		$stmt->finish();
		$count = $row->{'count'};
		$dbh->disconnect() || die $DBI::errstr;
	};
	if ($@) {
		print($@);
		return 0;
	}
	return $count == 2;
}

sub new{
	my $class = shift;
	my $self = {
		'root' => {},
		'dbh' => 0
	};
	bless $self, $class;
	return $self;
}

sub Parse{
	# Parses the bookmark data
	my ($self, $args) = @_;

	my $filename = $args->{'filename'};

	$self->{'dbh'} = DBI->connect("DBI:SQLite:dbname=$filename", '', '', {RaiseError => 1}) || die $DBI::errstr;

	$self->FetchDirectories();
	$self->FetchLinks();
}

sub FetchDirectories{
	my ($self, $args) = @_;

	my $stmt = $self->{'dbh'}->prepare($DIRECTORY_QUERY) || die $DBI::errstr;
	$stmt->execute() || die $DBI::errstr;

	while (my $row = $stmt->fetchrow_hashref()) {
		$row->{'type'} = 'text/x-moz-place-container';
		my $node = $self->FindNodeByID({node => $self->{'root'}, needle => $row->{'parent'}});
		if (!$node) {
			$self->{'root'} = $row;
		} else {
			push(@{$node->{'children'}}, $row);
		}
	}
}

sub FetchLinks{
	my ($self, $args) = @_;

	my $stmt = $self->{'dbh'}->prepare($LINK_QUERY) || die $DBI::errstr;
	$stmt->execute() || die $DBI::errstr;

	while (my $row = $stmt->fetchrow_hashref()) {
		$row->{'type'} = 'text/x-moz-place';
		my $node = $self->FindNodeByID({node => $self->{'root'}, needle => $row->{'parent'}});
		push(@{$node->{'children'}}, $row);
	}
}

sub StringifyBookmark{
	# Stringify a single Bookmark (non-folder)
	my ($self, $args) = @_;

	my $node = $args->{'node'};
	my $indent = " " x $args->{'indent'};

	return "$indent$node->{'title'}\n" .
		"$indent  URI:           $node->{'uri'}\n" .
		"$indent  Visit Count:   $node->{'visit_count'}\n" .
		"$indent  Added:         $node->{'dateAdded'} - " . DateTime->from_epoch(epoch=>$node->{'dateAdded'} / 1000000) . "\n" .
		"$indent  Last Modified: $node->{'lastModified'} - " . DateTime->from_epoch(epoch=>$node->{'lastModified'} / 1000000) . "\n" . 
		"$indent  Last Used:     $node->{'last_visit_date'} - " . DateTime->from_epoch(epoch=>$node->{'last_visit_date'} / 1000000) . "\n";
}

sub FindNodeByID{
	my ($self, $args) = @_;

	my $currNode = $args->{'node'};
	my $needle = $args->{'needle'};

	return $currNode if (defined $currNode->{'id'} && $currNode->{'id'} == $needle);
	if (defined $currNode->{'children'}) {
		foreach (@{$currNode->{'children'}}) {
			my $result = $self->FindNodeByID({node => $_, needle => $needle});
			return $result if ($result);
		}
	}
	return 0;
}

1;
