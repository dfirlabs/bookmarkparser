#!/usr/bin/perl
#
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
# Main driver for browser bookmark parsing utility

use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/lib";

use ChromeBookmarkParser;
use FirefoxBookmarkSqliteParser;
use FirefoxBookmarkBackupParser;

binmode(STDOUT, "encoding(UTF-8)");

###############
# SUBROUTINES #
###############

sub ParseData{
	my ($args) = @_;

	my $parser;

	if (FirefoxBookmarkBackupParser::CanHandle({filename => $args->{'filename'}})) {
		$parser = FirefoxBookmarkBackupParser->new();
	} elsif (FirefoxBookmarkSqliteParser::CanHandle({filename => $args->{'filename'}})) {
		$parser = FirefoxBookmarkSqliteParser->new();
	} elsif (ChromeBookmarkParser::CanHandle({filename => $args->{'filename'}})) {
		$parser = ChromeBookmarkParser->new();
	} else {
		die "No usable parser for file";
	}
	
	$parser->Parse({filename => $args->{'filename'}});

	return $parser;
}

####################
# MAIN STARTS HERE #
####################

my $filename = shift || die "Please specify a file";
my $searchRegex = shift;

my $parser = ParseData({filename => $filename});

if (defined($searchRegex)) {
	$parser->Search({needle => $searchRegex});
} else {
	$parser->DumpAll();
}
