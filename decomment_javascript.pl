#! /usr/bin/perl -w

###################################################################################################
# In actual fact, all we really need to do is strip comments - crunching down to an unreadable
# point may just hurt debugging. As such, we only need to strip lines that start with '//' or have
# some whitespace, then '//'.
###################################################################################################

# Edit this!
my $file = 'public/javascripts/local.js';

my $content = '';
open(FILE, $file);

while ($line = <FILE>) {
	if ($line =~ m/^\s*\/\/(.*)/) {
		# comment line, ignore
	} else {
		$content .= $line;
	}
}
close(FILE);

open(FILE, ">$file");
print FILE $content;
close(FILE);
