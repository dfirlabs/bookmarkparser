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
# ChromeBookmarkParser.pm
#
# Chrome implementation of bookmark parsing.

use strict;
use warnings;

package ChromeBookmarkParser;

use parent 'BookmarkParser';

use DateTime;
use JSON;


sub CanHandle{
	# Returns 1 if this parser can handle the data parssed in {data => "bookmark data"}, 0 otherwise.
	my ($args) = @_;

	my $filename = $args->{'filename'};
	my $json;

	open(FH, '<', $filename) || die "error opening $filename: $!";
	my $data = do { local $/; <FH> };
	close FH;

	# Chrome bookmarks are JSON, with root keys "checksum", "roots" and "version".
	eval {
		$json = decode_json($data);
	};
	return 0 if ($@);
	return 1 if exists $json->{'checksum'} and exists $json->{'roots'} and exists $json->{'version'};
	return 0;
}

sub new{
	my $class = shift;
	my $self = {
		'root' => {},
	};
	bless $self, $class;
	return $self;
}

sub Parse{
	# Parses the bookmark data
	my ($self, $args) = @_;

	my $filename = $args->{'filename'};

	open(FH, '<', $filename) || die "error opening $filename: $!";
	my $data = do { local $/; <FH> };
	close FH;

	$self->{'root'} = decode_json($data);
}

sub DumpAll{
	# Dumps the bookmark data to stdout.
	my ($self, $args) = @_;

	
	foreach my $key (keys %{$self->{'root'}->{'roots'}}){
		$self->DumpNode({node => $self->{'root'}->{'roots'}->{$key}, indent => 0});
	}
}

sub DumpNode{
	# Recursively dump a single node to stdout
	my ($self, $args) = @_;

	my $node = $args->{'node'};
	my $indent = " " x $args->{'indent'};

	if ($node->{'type'} eq 'folder') {
		print("$indent$node->{'name'}/\n");
		print("$indent  Added:         $node->{'date_added'} - " . HumanReadableChromeDate($node->{'date_added'}) . "\n");
		print("$indent  Last Modified: $node->{'date_modified'} - " . HumanReadableChromeDate($node->{'date_modified'}) . "\n");
		print("$indent  Last Used:     $node->{'date_last_used'} - " . HumanReadableChromeDate($node->{'date_last_used'}) . "\n");
		print("$indent  Children:\n");
		foreach (@{$node->{'children'}}) {
			$self->DumpNode({node => $_, indent => $args->{'indent'} + 4});
		}
	} else {
		# Is a bookmark
		print($self->StringifyBookmark({node => $node, indent => $args->{'indent'}}));
	}
}

sub StringifyBookmark{
	# Stringify a single Bookmark (non-folder)
	my ($self, $args) = @_;

	my $node = $args->{'node'};
	my $indent = " " x $args->{'indent'};

	return "$indent$node->{'name'}\n" .
		"$indent  URL:       $node->{'url'}\n" .
		"$indent  Added:     $node->{'date_added'} - " . HumanReadableChromeDate($node->{'date_added'}) . "\n" .
		"$indent  Last Used: $node->{'date_last_used'} - " . HumanReadableChromeDate($node->{'date_last_used'}) . "\n";
}

sub HumanReadableChromeDate{
	# Chrome/Webkit timestamps are microsends since 1601-01-01T00:00:00Z
	my $ticks = shift;
	my $dt = DateTime->new(year => 1601, month => 01, day => 01, hour => 0, minute => 0, second => 0, time_zone => 'UTC');
	$dt->add(seconds => $ticks / 1000000);
	return $dt
}

sub Search{
	# Searches for bookmarks with fields that matches a regex
	my ($self, $args) = @_;

	my $needle = $args->{'needle'};

	my @results;

	foreach my $key (keys %{$self->{'root'}->{'roots'}}){
		push(@results, $self->SearchNode({node => $self->{'root'}->{'roots'}->{$key}, needle => $needle, indent => 0}));
	}

	print $_ foreach (reverse(@results));
}

sub SearchNode{
	# Recursively searches a node for a needle
	my ($self, $args) = @_;

	my $node = $args->{'node'};
	my $needle = $args->{'needle'};
	my $indent = " " x $args->{'indent'};

	if ($node->{'type'} eq 'folder') {
		my @results;
		foreach (@{$node->{'children'}}) {
			push(@results, $self->SearchNode({node => $_, needle => $needle, indent => $args->{'indent'} + 4}));
		}
		if (scalar(@results)) {
			push(@results, "$indent$node->{'name'}/\n");
		}
		return @results;
	} else {
		if ($node->{'name'} =~ /$needle/i || $node->{'url'} =~ /$needle/i) {
			return $self->StringifyBookmark({node => $node, indent => $args->{'indent'}});
		}
		return;
	}
}


1;
