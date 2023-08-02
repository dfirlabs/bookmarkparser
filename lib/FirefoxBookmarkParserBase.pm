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
# FirefoxBookmarkParserBase.pm
#
# Firefox implementation of bookmark parsing.

use strict;
use warnings;

package FirefoxBookmarkParserBase;

use parent 'BookmarkParser';


sub DumpAll{
	# Dumps the bookmark data to stdout.
	my ($self, $args) = @_;

	$self->DumpNode({node => $self->{'root'}, indent => 0});
}

sub DumpNode{
	# Recursively dump a single node to stdout
	my ($self, $args) = @_;

	my $node = $args->{'node'};
	my $indent = " " x $args->{'indent'};

	if ($node->{'type'} eq 'text/x-moz-place-container') {
		# Is a directory
		print($indent . ($node->{'title'} ? $node->{'title'} : $node->{'guid'}) . "/\n");
		print("$indent  Added:        $node->{'dateAdded'} - " . DateTime->from_epoch(epoch=>$node->{'dateAdded'} / 1000000) . "\n");
		print("$indent  LastModified: $node->{'lastModified'} - " . DateTime->from_epoch(epoch=>$node->{'lastModified'} / 1000000) . "\n");
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

	return "$indent$node->{'title'}\n" .
		"$indent  URI:          $node->{'uri'}\n" .
		"$indent  Added:        $node->{'dateAdded'} - " . DateTime->from_epoch(epoch=>$node->{'dateAdded'} / 1000000) . "\n" .
		"$indent  LastModified: $node->{'lastModified'} - " . DateTime->from_epoch(epoch=>$node->{'lastModified'} / 1000000) . "\n";
}

sub Search{
	# Searches for bookmarks with fields that matches a regex
	my ($self, $args) = @_;

	my $needle = $args->{'needle'};

	my @results = $self->SearchNode({node => $self->{'root'}, needle => $needle, indent => 0});

	print $_ foreach (reverse(@results));
}

sub SearchNode{
	# Recursively searches a node for a needle
	my ($self, $args) = @_;

	my $node = $args->{'node'};
	my $needle = $args->{'needle'};
	my $indent = " " x $args->{'indent'};

	if ($node->{'type'} eq 'text/x-moz-place-container') {
		my @results;
		foreach (@{$node->{'children'}}) {
			push(@results, $self->SearchNode({node => $_, needle => $needle, indent => $args->{'indent'} + 4}));
		}
		if (scalar(@results)) {
			push(@results, "$indent$node->{'title'}/\n");
		}
		return @results;
	} else {
		if ($node->{'title'} =~ /$needle/i || $node->{'uri'} =~ /$needle/i) {
			return $self->StringifyBookmark({node => $node, indent => $args->{'indent'}});
		}
		return;
	}
}

1;
