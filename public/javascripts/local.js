// adds commas into a number for output
function commafy (number) {
	number += '';

	// make sure number doesn't already have commas
	check = number.split(',');
	if (check.length > 1) {
		return number;
	}

	x = number.split('.');
	x2 = x.length > 1 ? '.' + x[1] : '';
	var rgx = /(\d+)(\d{3})/;
	while (rgx.test(x[0])) {
		x[0] = x[0].replace(rgx, '$1' + ',' + '$2');
	}
	return x[0] + x2;
}

// Finds the currency symbol and removes the html entity encoding if we're using DOM.
function get_currency_symbol(symbol) {
	return (symbol == null) ? (asset_symbols['price'] ? asset_symbols['price'].unescapeHTML() : '$') : symbol;
}

// print out a price
function format_price(number, symbol) {
	var symbol = get_currency_symbol(symbol);

	if(number.toFixed) {
		return symbol + commafy(number.toFixed(2));
	}
	return symbol + commafy(number);
}

// print out a discount
function format_discount(number, symbol) {
	var symbol = get_currency_symbol(symbol);

	if(number.toFixed) {
		return '(Normally ' + symbol + commafy(number.toFixed(2)) + ')';
	}
	return '(Normally ' + symbol + commafy(number) + ')';
}

// print out a weight
function format_weight(number, symbol) {
	var symbol = (symbol == null) ? (asset_symbols['weight'] ? asset_symbols['weight'] : 'kg') : symbol;

	if(number.toFixed) {
		return '(' + commafy(number.toFixed(3)) + symbol + ')';
	}
	return '(' + commafy(number) + symbol + ')';
}

// print out a weight as shown in the 'view cart' area
function format_cart_weight(number, symbol) {
	var symbol = (symbol == null) ? (asset_symbols['weight'] ? asset_symbols['weight'] : 'kg') : symbol;

	if(number.toFixed) {
		return commafy(number.toFixed(3)) + symbol;
	}
	return commafy(number) + symbol;
}

// Uses the local 'asset_symbols' var.
function format_asset(asset_type, number) {
	return eval('format_' + asset_type + '(' + number + ')');
}

// updates an asset (typically 'price' or 'weight') displayed for a product, based on the product
// options chosen. Uses the locally cached asset values (in the 'prices_weights' var), so doesn't
// cause any Ajax calls.
//
// thanks to changes, there are now possibly multiple asset values to update for a single product.
// MultiLineOption's mean potentially N sequential forms, each with its own assets to update.
function update_product_asset (product_div, asset_type) {
	total_asset = 0.0;

	var bits = product_div.id.split('-');

if (bits.length < 5) {
	alert('id is: ' + product_div.id);
	alert('className is: ' + product_div.className);
	alert('id is: ' + product_div.parentNode.id);
	alert('className is: ' + product_div.parentNode.className);
}

	var prod_id = parseInt(bits[3]);
	var counter_id = parseInt(bits[4]);

	// there should be one '.ASSET' element, which has an id = 'ASSET-'.PRODID.'-'.COUNTERID
	output_span = document.getElementsByClassName(asset_type, product_div);
	if (output_span.length == 0)
	{
		return false;
	}
	output_span = output_span[0];
//	prod_id = parseInt(output_span.id.substr(asset_type.length + 1));

	// STOP USING IF() SAM! STOP IT!
	if (typeof(window['output_span']) != 'undefined' && window['output_span'] != null) {
//	if (output_span) {
		total_asset += prices_weights[prod_id][0][asset_type];

		option_value_inputs = document.getElementsByClassName('option_value', product_div);
		option_value_inputs.each( function(option_value_input) {
			// this should handle multiple-select boxes
			if (option_value_input.multiple) {
				for (var counter = 0; counter < option_value_input.length; counter++) {
					if (option_value_input.options[counter].selected) {
						total_asset += prices_weights[prod_id][parseInt(option_value_input.name.substr(7))][option_value_input.options[counter].value][asset_type];
					}
				}
			} else {
				// this is either a single input option-value, or a multi-checkbox
				// option-value
				if (option_value_input.type == 'checkbox') {
					if (option_value_input.checked) {
						total_asset += prices_weights[prod_id][parseInt(option_value_input.name.substr(7))][option_value_input.value][asset_type];
					}
				} else {
					if (option_value_input.type == 'radio') {
						if (option_value_input.checked) {
							total_asset += prices_weights[prod_id][parseInt(option_value_input.name.substr(7))][option_value_input.value][asset_type];
						}
					} else {
						if (option_value_input.value) {
							total_asset += prices_weights[prod_id][parseInt(option_value_input.name.substr(7))][option_value_input.value][asset_type];
						}
					}
				}
			}
		});

		if (asset_type == 'price') {
			if (prices_weights[prod_id][0]['discount'] > 0) {
				// the span with the 'normally X'
				original_span = output_span;
				output_span = $('discount-' + prod_id + '-' + counter_id);

				// now update the original (undiscounted) price displayed
				if (original_span.textContent) {
					original_span.textContent = format_asset('discount', total_asset, true);
				} else {
					original_span.innerHTML = format_asset('discount', total_asset, false);
				}
				original_span.title = format_asset('discount', total_asset, false);

				// change the price to the discounted value
				if (prices_weights[prod_id][0]['discount_is_abs'] > 0) {
					total_asset -= prices_weights[prod_id][0]['discount'];
				} else {
					total_asset -= (total_asset * prices_weights[prod_id][0]['discount'] / 100);
				}
			}
		}

		// now update the asset value displayed
		if (output_span.textContent) {
			output_span.textContent = format_asset(asset_type, total_asset, true);
		} else {
			output_span.innerHTML = format_asset(asset_type, total_asset, false);
		}
		output_span.title = format_asset(asset_type, total_asset, false);
	}
}

// Used as an iterator, so needs to just take the iterated value.
function update_product_price (product_div) {
	return update_product_asset(product_div, 'price');
}

// Used as an iterator, so needs to just take the iterated value.
function update_product_weight (product_div) {
	return update_product_asset(product_div, 'weight');
}

// Used on onChange events for product options, to update their product
function update_from_product_option (product_option_element) {
	the_el = product_option_element
	found_container = false;
	while (!found_container) {
		the_el = the_el.parentNode;

		if (the_el == $('container')) {
			// couldn't find product element - quit
			// alert('ERROR: could not find product element!');

			// this now also happens on a Featured Product!
			update_product_asset(product_option_element, 'price');
			return false;
		}

		classes = the_el.className.split(' ');
		for (var counter = 0; counter < classes.length; counter++) {
			if (classes[counter] == 'product-details-form') {
				found_container = true;
			}
		}
	}
	update_product_asset(the_el, 'price');
	update_product_asset(the_el, 'weight');
}

// Updates a price/weight/etc for a single product option.
function cart_update_product_asset(x_counter, option_id, asset_type) {
	product_id = 0;
	prices_weights[x_counter].each( function(product_array, product_i) {
		if (product_array) {
			product_id = product_i;
		}
	});
	asset = asset_type;
	if (asset == 'cart_weight') {
		asset = 'weight';
	}
	the_el = $(asset + '_' + x_counter + '_' + product_id + '_' + option_id);

	value = prices_weights[x_counter][product_id][option_id][$F('option[' + x_counter + '][' + option_id + ']')][asset];

	if (asset == 'price' && prices_weights[x_counter][product_id][0]['discount'] > 0) {
		if (prices_weights[x_counter][product_id][0]['discount_is_abs'] == 0) {
			value -= value * (prices_weights[x_counter][product_id][0]['discount'] / 100);
		}
	}

	if (the_el.textContent) {
		the_el.textContent = '+' + format_asset(asset_type, value);
	} else {
		the_el.innerHTML = '+' + format_asset(asset_type, value);
	}
}

// Used on onChange events for product options in the 'view cart' area, to update their product
function cart_update_from_product_option (product_option_element) {
	the_el = product_option_element;

	name_bits = the_el.name.split('[');

	x_counter = name_bits[1].substr(0, name_bits[1].length - 1);
	option_id = name_bits[2].substr(0, name_bits[1].length - 1);

	cart_update_product_asset(x_counter, option_id, 'price');
	if ($('grand_weight')) {
		cart_update_product_asset(x_counter, option_id, 'cart_weight');
	}
	cart_update_totals_and_grands();
}

// Used to update all the total prices and grand total price/weight/qty values in the 'view cart'
// area. Called on a product option or qty change.
function cart_update_totals_and_grands () {
	grand_qty = 0;
	grand_weight = 0.0;
	grand_total = 0.0;

	visible_products.each( function(product_id, x_counter) {
		product_qty = $F('qty[' + x_counter + ']');
		grand_qty += parseInt(product_qty);
		product_weight = prices_weights[x_counter][product_id][0]['weight'];
		product_price = prices_weights[x_counter][product_id][0]['price'];
		if (prices_weights[x_counter][product_id][0]['discount'] > 0) {
			if (prices_weights[x_counter][product_id][0]['discount_is_abs'] > 0) {
				product_price -= prices_weights[x_counter][product_id][0]['discount'];
			} else {
				product_price -= product_price * (prices_weights[x_counter][product_id][0]['discount'] / 100);
			}
		}

		// now add in all the product-option extra weights/costs
		prices_weights[x_counter][product_id].each( function(option_array, option_i) {
			if (option_i > 0) {
				if (option_array) {
					product_weight += option_array[$F('option[' + x_counter + '][' + option_i + ']')]['weight'];

					option_price = option_array[$F('option[' + x_counter + '][' + option_i + ']')]['price'];
					if (prices_weights[x_counter][product_id][0]['discount'] > 0) {
						if (prices_weights[x_counter][product_id][0]['discount_is_abs'] == 0) {
							option_price -= option_price * (prices_weights[x_counter][product_id][0]['discount'] / 100);
						}
					}
					product_price += option_price;
				}
			}
		});
		grand_weight += product_weight;

		product_total = product_price * product_qty;
		grand_total += product_total;

		total_td = $('total_' + x_counter + '_' + product_id);
		if (total_td.textContent) {
			total_td.textContent = format_asset('price', product_total);
		} else {
			total_td.innerHTML = format_asset('price', product_total);
		}
	});

	grand_qty_td = $('grand_qty');
	if (grand_qty_td.textContent) {
		grand_qty_td.textContent = grand_qty;
	} else {
		grand_qty_td.innerHTML = product_total;
	}

	grand_weight_td = $('grand_weight');
	if (grand_weight_td) { // check - weights aren't necissarily shown
		if (grand_weight_td.textContent) {
			grand_weight_td.textContent = format_asset('cart_weight', grand_weight);
		} else {
			grand_weight_td.innerHTML = format_asset('cart_weight', grand_weight);
		}
	}

	grand_total_td = $('grand_total');
	if (grand_total_td.textContent) {
		grand_total_td.firstChild.textContent = format_asset('price', grand_total);
	} else {
		grand_total_td.innerHTML = '<strong>' + format_asset('price', grand_total) + '</strong>';
	}
}

// sends an Ajax call back to the site to reload all the prices and weights stored for products
// that are on display on the current page. The list of products on display should be in the global
// 'visible_products' variable.
function reload_price_weight_array(currency) {
	if (typeof(window['visible_products']) != 'undefined') {
		products = '';
		for (var counter = 0; counter < visible_products.length; counter++) {
			if (visible_products[counter]) {
				if (products == '') {
					products += visible_products[counter];
				} else {
					products += ',' + visible_products[counter];
				}
			}
		}
		var array_div = $('array_div');

		if (typeof(showing_objects) != 'undefined' && showing_objects == 'lineitems') {
			new Ajax.Updater(array_div, '/conversions/prices_cart/?currency=' + currency, {asynchronous:true,evalScripts:true});
		} else {
			new Ajax.Updater(array_div, '/conversions/prices/?products=' + products + '&currency=' + currency, {asynchronous:true,evalScripts:true});
		}
	}
	return false;
}

// refreshes the prices of products listed on the page (outside the cart preview area)
function refresh_prices() {
	// refresh the display of any products
	product_divs = document.getElementsByClassName('product-details-form');
	product_divs.each( update_product_price );
}

// refreshes the prices of line items listed on the page (outside the cart preview area). Only used
// in the 'view cart' area
function refresh_prices_cart() {
	prices_weights.each( function (products, item_i) {
		products.each( function (option_array, prod_i) {
			if (option_array) {
				// update base price
				price_el = $('price_' + item_i + '_' + prod_i);
				price_val = option_array[0]['price'];
				if (price_el.textContent) {
					price_el.textContent = format_asset('price', price_val);
				} else {
					price_el.innerHTML = format_asset('price', price_val);
				}

				// update base weight
				weight_el = $('weight_' + item_i + '_' + prod_i);
				weight_val = option_array[0]['weight'];
				if (weight_el.textContent) {
					weight_el.textContent = format_asset('cart_weight', weight_val);
				} else {
					weight_el.innerHTML = format_asset('cart_weight', weight_val);
				}

				// loop through all options
				option_array.each( function(values_array, option_i) {
					if (values_array) {
						if (option_i > 0) {
							// update the price and weight
							cart_update_product_asset(item_i, option_i, 'price');
							cart_update_product_asset(item_i, option_i, 'cart_weight');
						}
					}
				});
			}
		});
	});

	cart_update_totals_and_grands();
}

// updates any prices displayed in the 'cart summary' via Ajax calls. One async Ajax call per price
function update_cart_currency(currency) {
	spans = document.getElementsByClassName('price', $('cart-contents'));
	spans.each( function(s){
		if (s.title) {
			if (s.textContent) {
				s.textContent = 'converting...';
			} else {
				s.innerHTML = 'converting...';
			}
			new Ajax.Updater(s, '/conversions/price/?amount=' + escape(s.title) + '&currency=' + currency, {asynchronous:true});
		}
	});
}

// run when a user changes the currency they wish to view prices in. Does a single Ajax callback to
// update the prices array for products being viewed, as well as an Ajax callback for each product
// in the cart.
function currency_conversion(currency) {
	spans = document.getElementsByClassName('price');
	spans.each( function(s) {
		if (s.textContent) {
			s.textContent = 'converting...';
		} else {
			s.innerHTML = 'converting...';
		}
	});

	spans = document.getElementsByClassName('discount');
	spans.each( function(s) {
		if (s.textContent) {
			s.textContent = 'converting...';
		} else {
			s.innerHTML = 'converting...';
		}
	});

	// now, update the prices (and weights) array
	reload_price_weight_array(currency);
}

// updates all prices on the page that are in 'price' class elements.
// DEPRECATED function - this is now replaced with currency_conversion()
function update_prices(currency) {
	spans = document.getElementsByClassName("price");
	spans.each( function(s){
		if (s.title) {
			if (s.textContent) {
				s.textContent = 'converting...';
			} else {
				s.innerHTML = 'converting...';
			}
			new Ajax.Updater(s, '/conversions/price/?amount=' + escape(s.title) + '&currency=' + currency, {asynchronous:true});
		}
	});
}

var menu_timeout = null;
var i = 0;

Effect.Transitions.EaseOut = function(pos) {
	return 1-Math.pow(1-pos,3);
}

Effect.Transitions.EaseIn = function(pos) {
	return Math.pow(pos,3);
}

function show_products_menu() {
	if (!menu_timeout) {
		Element.setOpacity('sub-products', 0.85);
		cancel_menu_animation();
		new Effect.SlideDown('sub-products', { duration:0.5, transition:Effect.Transitions.EaseOut, queue: { position:'end', scope:'menu' } });
	}
	reset_timeout();
}

function reset_timeout() {
	if (menu_timeout) {
		clearTimeout(menu_timeout);
	}
	menu_timeout = setTimeout(function() { hide_products_menu() }, 2000);
}

function hide_products_menu() {
	if (menu_timeout) {
		clearTimeout(menu_timeout);
		menu_timeout = null;
		cancel_menu_animation();
		new Effect.SlideUp('sub-products', { duration:0.5, transition:Effect.Transitions.EaseIn, queue: { position:'end', scope:'menu' } });
	}
}

function cancel_menu_animation() {
	//q = Effect.Queues.get('menu');
	//q.each(function(e) { e.cancel() });
	//m = $('menu-products');
	//Element.undoClipping(m);
}

// Used by the options editor.
function option_collapse(option_id)
{
	$('option-form-' + option_id).remove();
	$('legend-' + option_id + '-closer').hide();
	$('legend-' + option_id + '-opener').show();
	return false;
}

// Used by the product types editor.
function product_type_collapse(product_type_id)
{
	$('product-type-form-' + product_type_id).remove();
	$('legend-' + product_type_id + '-closer').hide();
	$('legend-' + product_type_id + '-opener').show();
	return false;
}

// Used by the options editor.
function option_action(option_id, value_id, action)
{
	$('option-' + option_id + '-value').value = value_id;
	$('do-' + option_id).value = action;
	$('option-form-' + option_id).onsubmit();
	return false;
}

// Used by the product types editor.
function product_type_action(product_type_id, value_id, action)
{
	$('product-type-' + product_type_id + '-value').value = value_id;
	$('do-' + product_type_id).value = action;
	$('product-type-form-' + product_type_id).onsubmit();
	return false;
}

function show_discount_abs_perc()
{
	if ($('featured_product_discount_is_abs')) {
		form_el = $F('featured_product_discount_is_abs');
	} else {
		form_el = $F('product_discount_is_abs');
	}

	abs_el = $('discount_absolute');
	perc_el = $('discount_percent');
	space = '&nbsp;'.unescapeHTML();

	if (form_el == 'true') {
		if (abs_el.textContent) {
			abs_el.textContent = '$';
			perc_el.textContent = space;
		} else {
			abs_el.innerHTML = '$';
			perc_el.innerHTML = space;
		}
	} else {
		if (abs_el.textContent) {
			abs_el.textContent = space;
			perc_el.textContent = '%';
		} else {
			abs_el.innerHTML = space;
			perc_el.innerHTML = '%';
		}
	}
}

function discount_use_base_price() {
	var price_el = $('featured_product_base_price');
	if($('featured_product_use_base_price').checked) {
		price_el.value = '0.00';
		price_el.disable();
	}
	else
		price_el.enable();
}

// Used in the shipping-zone editor to get rid of lengthy AJAX calls which were having trouble
// when the user double-clicks on the button (plus doing this locally is much more responsive).
function move_selected_options(src_list, dest_list) {
	src = $(src_list);
	dest = $(dest_list);
	var found = false;
	for(var i = src.options.length - 1; i >=0 ; i--) {
		if(src.options[i].selected) {
			dest.options[dest.options.length] = new Option(src.options[i].text, src.options[i].value);
			src.options[i] = null; // delete the option
		}
		found = true;
	}
	// Now we want to sort the dest_list alphabetically.  Unfortunately, even though the Sun Client-Side
	// Javascript Reference says that the 'options' property is an array, and it can be mostly be treated
	// as such, it isn't really a true array as it has no sort() method.
	if(found) // don't bother sorting if there weren't any options selected
		sort_select_options(dest_list);
	return false;
}

// A hack to get around the fact that the options in a select list aren't really a proper array...
function sort_select_options(option_list) {
	src = $(option_list);
	var temp = new Array();
	for(var i = 0; i < src.options.length; i++) {
		temp[temp.length] = new Option(src.options[i].text, src.options[i].value, src.options[i].defaultSelected, src.options[i].selected);
	}

	temp.sort(option_sorter)

	src.options.length = 0;
	for(i = 0; i < temp.length; i++) {
		src.options[i] = new Option(temp[i].text, temp[i].value, temp[i].defaultSelected, temp[i].selected);;
	}
}

// callback for sorting option lists.  Returns 1 if a > b, 0 if equivalent or -1 if b > a.
function option_sorter(a, b) {
	return (a.text == b.text) ? 0 : ( (a.text > b.text) ? 1 : -1);
}

// This is called to submit the zone editing form.  We have to select all of the elements in the
// 'include' dialog so they'll be sent to the server for processing.
function send_zone_form(zone_id) {
	zone_el = $('zone_' + zone_id + '_editor');
	include_el = $('include_' + zone_id);
	for(var i = 0; i < include_el.options.length; i++) {
		include_el.options[i].selected = true;
	}
	zone_el.onsubmit();
}

function show_toggle(togglable_id, widget_id) {
	hider = $(togglable_id);
	widget = $(widget_id);

	if (hider.style.display == 'none') { // show it
		Element.show(hider);

		if (widget.textContent) {
			widget.textContent = '&ndash;'.unescapeHTML(); // The width of this is more consistent with that of a '+'.
		} else {
			widget.innerHTML = '&ndash;'.unescapeHTML();
		}
	} else { // hide it
		Element.hide(hider);

		if (widget.textContent) {
			widget.textContent = '+';
		} else {
			widget.innerHTML = '+';
		}
	}

	return true;
}

function hide_show_icon_sets() {
	new_sets = document.getElementsByClassName('icon_set');

	new_sets.each(function(node){
		Element.hide(node);
	});
	Element.show($('icon_set_' + $('new_set').value));
}

function hide_show_icon_types(set_name, format_to_show) {
	all_types = document.getElementsByClassName(set_name + '_formatted_icons');

	all_types.each(function(node){
		Element.hide(node);
	});
	Element.show($(format_to_show + '_icons_' + set_name));
}
