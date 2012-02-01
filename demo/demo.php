<?php
/*
	demo.php: controls the admin-demo user's password.  Configuration is picked up automatically from
	the rocketcart.yml and database.yml files.

	DEPENDENCIES:
		../public/payments/lib.php (for the load_yaml() function)
		../config/database.yml
		../config/rocketcart.yml

	USAGE: php demo.php start|stop|db_details password
		(password is only required for 'start')
*/

// *** Begin configuration ***

// This is what the password will be changed to when we're called with 'stop'.
$default_password = 'tr1p2space';

// *** End configuration ***

// This gets us the load_yaml and get_db_settings() functions
include('../public/payments/lib.php');

// These paths seem to be relative to the load_yaml function in ../public/payments.
$app_config = load_yaml('../config/rocketcart.yml');
// This automagically picks up the correct environment.
$db_config = get_db_settings('../config/database.yml');

if(!isset($app_config['demo']))
	bomb('Error: There is no demo user configured in rocketcart.yml!');

if(!isset($app_config['demo']['enabled']) || ($app_config['demo']['enabled'] != 'true'))
	bomb('Error: The demo user is not enabled in rocketcart.yml!');

if(!isset($app_config['demo']['user']))
	bomb('Error: The demo user is not configured in rocketcart.yml!');

$user = $app_config['demo']['user'];

switch(strtolower($argv[1])) {
	case 'start':
		demo_start();
		break;
	case 'stop':
		demo_stop();
		break;
	case 'db_details':
		print_db_details();
		break;
	default:
		help();
		break;
}

exit(0);

// This allows the start/stop scripts to pick up the database login details for dump/restore.
function print_db_details() {
	global $db_config;
	echo $db_config['database'] . ' ' . $db_config['username'] . ' ' . $db_config['password'];
}

// help(): show some help.
function help() {
	global $argv;
	echo 'Usage: ' . $argv[0] . ' start|stop password\n    (password is only required for \'start\')';
}

// demo_start(): Set a new password.
function demo_start() {
	global $argc, $argv;
	if($argc < 3)
		bomb('Error: Please supply a password.');
	update_db($argv[2]);
}

// demo_stop(): Restore the default password.
function demo_stop() {
	global $default_password;
	update_db($default_password);
}

// update_db(): Sets the new password in the database.
function update_db($new_password) {
	global $user, $db_config;
	$db = @mysql_connect($db_config['host'], $db_config['username'], $db_config['password'])
		or bomb('Error: Could not connect to the database!');
	$result = @mysql_select_db($db_config['database'])
		or bomb('Error: Could not select database: check configuration!');
	$user = @mysql_real_escape_string($user);
	$hashed_password = @mysql_real_escape_string(sha1($new_password));
	$result = @mysql_query('UPDATE users SET hashed_password = \'' . $hashed_password . '\' WHERE email = \'' . $user . '\';', $db)
		or bomb('Error in database query!');
	// I don't bother checking mysql_affected_rows() as this will return 0 if a row was matched but not updated.
	@mysql_close($db);
}

// bomb(): largely equivalent to die() but lets me control the exit code.
function bomb($msg) {
	echo $msg . "\n";
	exit(1);
}

?>