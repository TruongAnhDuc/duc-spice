# This script will upgrade a RocketCart site to the latest version of RocketCart. It assumes that
# an updated copy of the /app directory is situated in /app_new. All other directories should be
# updated before running this script.
#
# Normally the app_new directory will be created by running:
# cp -R app app_new
# ...and then overwriting files with the latest versions from Subversion, merging site-specific
# tweaks as necissary.
#
# This script follows the order:
# - put up 'maintenance' placeholder
# - make a backup of the database
# - migrate the database to the latest revision
# - update the /app directory
# - remove the 'maintenance' placeholder
#
# Called via:
# perl upgrade.pl

use YAML;

open(MAINTENANCE, '> public/index.html') or die('error opening maintenance placeholder file:'."$!");

$text = <<ENDSTRING;
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
   "http://www.w3.org/TR/html4/loose.dtd">
<html>
<body>
  <h1>Site Under Maintenance</h1>
  <p>This website is currently being upgraded as part of regular maintenance. Please try again shortly - we anticipate a minute or two of downtime. We apologise for any inconvenience.</p>
</body>
</html>
ENDSTRING

print MAINTENANCE $text;

close(MAINTENANCE);

my($db_config) = YAML::LoadFile('config/database.yml');
my($backup_command) = 'mysqldump -u' . $db_config->{'production'}{'username'} . ' -p' . $db_config->{'production'}{'password'} . ' ' . $db_config->{'production'}{'database'} . ' > db_backup.sql';
# backup db
system($backup_command);

# for Rails 1.1+, becomes:
@args = ('rake', 'db:migrate');
system(@args);

# find the old chown values, for backup
my($ls_output) = `ls -l | grep app`;
my(@ls_lines) = split(/\n/, $ls_output);
my($group_value) = '';
my($user_value) = '';
for($counter = 0; $counter < scalar(@ls_lines); $counter++) {
	my($cur_line) = $ls_lines[$counter];
	chomp $cur_line;
	if(substr($cur_line, -3) == 'app') { # this is the right line
		my(@ls_bits) = split(' ', $cur_line);

		$group_value = $ls_bits[2];
		$user_value = $ls_bits[3];
	}
}

system('rm -fR app_old'); # in case an old upgrade hasn't been cleaned up
system('mv app app_old');
system('mv app_new app');

# restore permissions
if($group_value != '' && $user_value != '') {
	system('chown -R ' . $group_value . ':' . $user_value . ' app');
}

system('rm -f public/index.html');

