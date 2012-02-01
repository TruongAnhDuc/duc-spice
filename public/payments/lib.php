<?php
	function load_yaml($filename) {
		$config = array();
		$config_file = file($filename);

		$old_indent = 0;
		$stack = array();
		$stack[0] =& $config;
		foreach ($config_file as $line) {
			if (!preg_match('/^\s*#/', $line)) {
				if (preg_match('/(\s*):?([^:]+):\s*(.*)/', $line, $matches)) {
					$indent = strlen($matches[1]);
					if ($indent < $old_indent) {
						for ($i = $indent + 1; $i <= $old_indent; $i++) {
							if (isset($stack[$i])) {
								unset($stack[$i]);
							}
						}
					}

					if (strlen($matches[3]) > 0) {
						$stack[$indent][$matches[2]] = $matches[3];
					} else {
						$stack[$indent][$matches[2]] = array();
						$stack[$indent + 2] =& $stack[$indent][$matches[2]];
					}
					$old_indent = $indent;
				}
			}
		}
		return $config;
	}

	function get_db_settings($filename = '../../../config/database.yml', $environment = 'production') {
		$db_config = load_yaml($filename);
		$db_params = $db_config[$environment];

// environment should be in a line in '../../config/environment.rb' like so:
//RAILS_ENV  = ENV['RAILS_ENV'] || 'development'
		$lines = file('../../../config/environment.rb');
		foreach($lines as $cur_line) {
			if(substr($cur_line, 0, 9) == 'RAILS_ENV') {
				$bits = explode('\'', $cur_line);
				$environment = $bits[3];
			}
		}

		$db_params = $db_config[$environment];

		return $db_params;
	}

	function find_records($query) {
		$q = mysql_query($query) or die(mysql_error());
		$results = array();
		while ($row = mysql_fetch_assoc($q)) {
			array_push($results, $row);
		}
		return $results;
	}

	function find_record($query) {
		$r = find_records($query . " LIMIT 1");
		if (empty($r)) {
			return null;
		} else {
			return $r[0];
		}
	}
?>