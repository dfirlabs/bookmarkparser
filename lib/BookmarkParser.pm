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
# BookmarkParser.pm
#
# Base class for browser bookmark storage file parsing

use strict;
use warnings;

package BookmarkParser;


sub CanHandle{
	# Returns 1 if this parser can handle the data parssed in {data => "bookmark data"}, 0 otherwise.
	die "Subroutine of base class called.";
}

sub new{
	die "Subroutine of base class called.";
}

sub Parse{
	# Parses the bookmark data
	die "Subroutine of base class called.";
}

sub Dumpall{
	# Dumps the bookmark data to stdout
	die "Subroutine of base class called.";
}

sub Search{
	# Searches for bookmarks with fields that matche a regex
	die "Subroutine of base class called.";
}

1;
