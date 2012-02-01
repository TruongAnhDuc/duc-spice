<?php
	include('config.php');
	include('../lib.php');

	$db_params = get_db_settings();
	$db = mysql_connect($db_params['host'], $db_params['username'], $db_params['password']) or die(mysql_error());
	mysql_select_db($db_params['database']);

	if (isset($_REQUEST['result'])) {
		$data = pack("H*", $_REQUEST['result']);
		$td = mcrypt_module_open('tripledes', '', 'ecb', '');
		$iv = mcrypt_create_iv(mcrypt_enc_get_iv_size($td), MCRYPT_RAND);
		mcrypt_generic_init($td, $encryption_key, $iv);
		$result = mdecrypt_generic($td, $data);
		$result = unserialize($result);
		$order_id = $result['reference'];

		switch ($result['status']) {
		case 'success':
			mysql_query("UPDATE orders SET status='awaiting_shipping' WHERE id=$order_id");
			header("Location: {$url_success}?id={$order_id}");
			break;
		default:
			mysql_query("UPDATE orders SET status='failed' WHERE id=$order_id");
			header("Location: {$url_failure}?id={$order_id}");
			break;
		}
	} else {
		$order_id = intval($_REQUEST['id']);
		$order = find_record('SELECT * FROM orders WHERE id=' .$order_id);
		$request = array();
		$request['reference'] = $order_id;
		$request['name'] = stripslashes($order['shipping_name']);
		$request['email'] = stripslashes($order['shipping_email']);
		$request['amount'] = floatval($order['total']);
		$data = serialize($request);

		$td = mcrypt_module_open('tripledes', '', 'ecb', '');
		$iv = mcrypt_create_iv(mcrypt_enc_get_iv_size($td), MCRYPT_RAND);
		mcrypt_generic_init($td, $encryption_key, $iv);
		$encrypted = mcrypt_generic($td, $data);
		$old_error_level = error_reporting(E_ERROR);
		$request = unpack('H*hex', $encrypted);
		error_reporting($old_error_level);

		$redirect_uri = 'https://www.rocketsecure.com/rocket-cart/?merchant_id=' . $merchant_id . '&request=' . $request['hex'];
		header('Location: ' . $redirect_uri);
	}


?>