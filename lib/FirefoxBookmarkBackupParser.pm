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
# FirefoxBookmarkBackupParser.pm
#
# Firefox implementation of bookmark parsing.

use strict;
use warnings;

package FirefoxBookmarkBackupParser;

use parent 'FirefoxBookmarkParserBase';

use Compress::LZ4;
use DateTime;
use JSON;


my $FF_HEADER = "mozLz40\x00";


sub CanHandle{
	# Returns 1 if this parser can handle the data parssed in {data => "bookmark data"}, 0 otherwise.
	my ($args) = @_;

	my $filename = $args->{'filename'};

	open(FH, '<', $filename) || die "error opening $filename: $!";
	my $data = do { local $/; <FH> };
	close FH;

	my $header = substr($data, 0, 8);

	# FF Bookmarks have a header "mozLz40\x00"
	return 1 if ($header eq $FF_HEADER);
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

	# Firefox bookmark files are LZ4 compressed JSON, but have an extra 8 byte header prepended.
	$data = substr($data, 8, length($data) - 8);
	$data = decompress($data);
	$self->{'root'} = decode_json($data);
}

1;
