# Controller for all admin-level functions for currencies. Checks to see if the currently logged-in
# user is a client before allowing access

class Admin::CurrenciesController < AdminController
	before_filter :authorise
	before_filter :defaults
	before_filter :require_authorisation_client
	helper :admin
	layout 'admin'


	# Displays a list of available currencies for editing, along with the time their exchange
	# rates were last updated.
	#
	# <b>Template:</b> <tt>admin/currencies/list.rhtml</tt>
	def list
		@current_area = 'currencies'
		@current_menu = 'settings'

		sort_order ||= get_sort_order("s-abbr", "abbreviation")
		sort_order ||= get_sort_order("s-name", "name")
		sort_order ||= get_sort_order("s-symbol", "symbol")
		sort_order ||= get_sort_order("s-rate", "exchange_rate")
		sort_order ||= "is_default DESC, name ASC"

		if params[:new] and params[:new_currency]
			params[:new_currency][:symbol] = params[:new_currency][:symbol_prefix] + Currency.symbols[params[:new_currency][:symbol]]
			params[:new_currency].delete('symbol_prefix')
			c = Currency.create(params[:new_currency])
			c.update_exchange_rate
		elsif params[:delete] and params[:select]
			c = params[:select].keys.collect { |k| "id=#{k}" }.join(' OR ')
			Currency.delete_all(c)
		elsif params[:default] and params[:select]
			c = params[:select].keys.first.to_i
			Currency.update_all('is_default = 0', 'is_default <> 0')
			Currency.update_all('is_default = 1', "id = #{c}")
		end

		@currencies = Currency.find(:all, :order => sort_order)
	end


	# Updates a Currency's exchange rate from Google. Called via AJAX.
	#
	# <b>Template:</b> <tt>admin/currencies/_exchange_rate.rhtml</tt>
	def update
		@currency = Currency.find(params[:id])
		@currency.update_exchange_rate
		render :partial => 'exchange_rate', :locals => { :currency => @currency }
	end

	# Displays a form for editing currency data.
	#
	# <b>Template:</b> <tt>admin/currencies/edit.rhtml</tt>
	def edit
		@current_area = 'currencies'
		@current_menu = 'settings'
		@currency = Currency.find(params[:id])

		@symbol = @currency.symbol.split('&', 2)
		if @symbol.length == 2
			@symbol_prefix = @symbol[0]
			@symbol = Currency.symbols.index('&' + @symbol[1])
			if @symbol.nil?
				@symbol = 'dollar'
			end
		else
			@symbol_prefix = ''
			@symbol = @currency.symbol
		end

		if @request.post?
			params[:currency][:symbol] = params[:currency][:symbol_prefix] + Currency.symbols[params[:currency][:symbol]]
			params[:currency].delete('symbol_prefix')
			@currency.update_attributes(params[:currency])
			redirect_to :action => :list
		end
	end
end
