README: demo scripts

This stuff is only used on the Rocket Cart Demo site rocketcart.avatar.co.nz!

Use demo/start new-password [time in days] to set a new admin password
which will automatically expire after the specified timespan (default is 2 days).

Calling demo/start again will restart the time, so you can grant a user more time
if they need it (yes, you will need to specify the password again).

demo/stop can be manually called to cut someone's session short.

Configuration
-------------

The only config necessary is in demo/demo.php.  Set up your application's mode (so the
correct database settings will be used) and a default password.  Everything else
should be automatically picked up from the Rocket Cart configuration.

TO DO
-----

1. See if it's possible to prevent atrm from sending mail every time a running job
   is deleted.  Hard to test as it needs to wait for mail delivery to occur.
	** I can't actually figure out why it's sending the mail to start with.  Nothing
	   I do on the command-line is triggering them.
