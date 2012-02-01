<?php
	include('pxaccess.inc');
	include('../lib.php');

	global $config;     $config = load_yaml('config.yml');
	global $app_config; $app_config = load_yaml('../../../config/rocketcart.yml');

	$db_params = get_db_settings();

	$db = mysql_connect($db_params['host'], $db_params['username'], $db_params['password']) or die(mysql_error());
	mysql_select_db($db_params['database']);

	$pxaccess = new PxAccess(
		$config['payment_express']['access_url'],
		$config['payment_express']['user_id'],
		$config['payment_express']['access_key'],
		$config['payment_express']['mac_key']
	);

	if (isset($_REQUEST['result'])) {
		payment_complete();
	} else {
		process_payment();
	}

	function quote_smart($value) {
		if (get_magic_quotes_gpc()) {
			$value = stripslashes($value);
		}

		if (!is_numeric($value)) {
			$value = '\'' . mysql_real_escape_string($value) . '\'';
		}

		return $value;
	}

	function payment_complete() {
		global $pxaccess;
		$enc_hex = $_REQUEST['result'];
		$response = $pxaccess->getResponse($enc_hex);
		$order_id = $response->getMerchantReference();

		if ($response->getStatusRequired() == "1") {
			// An error has occurred
			mysql_query('UPDATE orders SET status=\'failed\' WHERE id=' . $order_id);
			header('Location: /cart/payment_gateway/?id=' . $order_id);
			//redirect_to('/cart/payment_gateway/', $order_id);
  		} elseif ($response->getSuccess() == '1') {
			// The transaction was approved
			mysql_query('UPDATE orders SET status=\'awaiting_shipping\', gateway_used=\'payment-express\', response=' . quote_smart($response->toXml()) . ', paid=\'' . $response->AmountSettlement . '\' WHERE id=' . $order_id);
			header('Location: /cart/order_complete/?id=' . $order_id);
			//redirect_to('/cart/order_complete/', $order_id);
		} else {
			// The transaction was declined
			mysql_query('UPDATE orders SET status=\'failed\', gateway_used=\'payment-express\', response=' . quote_smart($response->toXml()) . ' WHERE id=' . $order_id);
			header('Location: /cart/payment_gateway/?id=' . $order_id);
			//redirect_to('/cart/payment_gateway/', $order_id);
		}
	}

	function process_payment() {
		global $pxaccess;
		$request = new PxPayRequest();

		$http_host   = getenv('HTTP_HOST');
		$request_uri = getenv('SCRIPT_NAME');
		$server_url  = 'http://' . $http_host;
		$script_url  = $server_url . $request_uri; // Using this code after PHP version 4.3.4

		$order_id = intval($_REQUEST['id']);
		$order = find_record('SELECT * FROM orders WHERE id=' . $order_id);

		if ($order['wholesale'])
		{
			$other_order = find_record('SELECT * FROM orders WHERE user_id=' . $order['user_id'] . ' AND status != \'in_progress\' AND status != \'draft\'');
			if ($other_order)
			{
				// this should never occur - these users should have been redirected away
				// from this payment gateway
				$request->setAmountInput(0.0);
			}
			else
			{
				$request->setAmountInput(round(floatval($order['total']) / 2, 2));
			}
		}
		else
		{
			$request->setAmountInput(floatval($order['total']));
		}
		$request->setTxnData1('Rocket Cart Payment');// whatever you want to appear
		$request->setTxnData2(stripslashes($order['shipping_name']));
		$request->setTxnType('Purchase');
		$request->setInputCurrency('NZD');
		// setCurrencyInput according to paymentexpress docs :?
		$request->setMerchantReference($order_id); // fill this with your order number
		$request->setEmailAddress($order['shipping_email']);
		$request->setUrlFail($script_url);
		$request->setUrlSuccess($script_url);

		// Call makeResponse of PxAccess object to obtain the 3-DES encrypted payment request
		$request_string = $pxaccess->makeRequest($request);
		header('Location: ' . $request_string);
	}

	function redirect_to($url, $id) {
?>
<html>
<head><title>Rocket Cart Payment Gateway</title></head>
<body onload="document.forms[0].submit();">
<form action="<?php echo $url; ?>" method="post">
Redirecting you back to our online store...
<input type="hidden" name="id" value="<?php echo $id; ?>" />
</form>
</body>
</html>
<?php
	}
?>