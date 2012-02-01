require 'open-uri'
require 'timeout'

# Represents a currency. Keeps track of conversion rates, fetching the current rate from Google if
# the cached value is older than a specified threshold (default is 24 hours)

class Currency < ActiveRecord::Base
	def to_s #:nodoc:
		name
	end

	# Returns +true+ if this currency is the default, or +false+ otherwise.
	def is_default?
		!is_default.zero?
	end

	# Converts an amount in New Zealand Dollars to this currency.
	def convert(amount)
		(amount * exchange_rate * 100).round / 100.00 unless !check_exchange_rate
	end

	# Converts and formats an amount in New Zealand Dollars using this currency.
	# Update: conversion is now optional.  If not converting, we leave out the currency symbol.
	def format(amount, convert_currency = true)
		if convert_currency
			sym = symbol
			amount = convert(amount)
		else
			sym = ''
		end
		s = sym + separator(sprintf('%.2f', amount))
	end

	# Formats a number with thousands-separators.  A certain other language has builtins to do this...
	# http://snippets.dzone.com/posts/show/693
	def separator(amount, separator = ',')
		amount.to_s.gsub(/(\d)(?=(\d\d\d)+(?!\d))/, '\\1' + separator)
	end

	# Checks the age of the cached exchange rate, and updates it if necessary.
	def check_exchange_rate
		if !update_every.zero? and (updated_at.nil? or updated_at < Time.now - update_every)
			update_exchange_rate
		else
			true
		end
	end

	# Updates the exchange rate from Google. Usually works to around four decimal places, which should be enough for an approximate
	# conversion (which is all we'll need).
	def update_exchange_rate
		successful = true
		timely = Timeout::timeout(5) do
			open("http://www.google.com/search?q=1+NZD+in+#{abbreviation}") do |f|
				matches = f.read.match(/1 New Zealand dollar = ([0-9]+(\.[0-9]+)?)/)
                if matches and matches.length > 0
					successful = update_attribute(:exchange_rate, matches[1].to_f)
                else
					successful = false
                end
			end
		end
		timely and successful
	end

	class << self
		# define symbols for the purposes of html entity encoding.
		# Because we use '&' as a delimiter, the first character of the values here MUST be encoded
		# whether or not they actually need to be.
		# The reason is that the value stored in the db (=prefix+symbol) must be able to be sent to
		# the client as-is, so we can't go adding other delimiters.
		SYMBOLS = {
			'dollar' => '&#36;',
			'pound' => '&pound;',
			'euro' => '&euro;',
			'yen' => '&yen;',
			'lira' => '&#8356;',
			'won' => '&#8361;',
			'yuan' => '&#20803;'
		}
		def symbols
			SYMBOLS
		end

		# Gets the default currency. If there aren't any in the database, makes one up for New Zealand Dollars.
		def default
			default_currency = Currency.find_by_is_default(1)
			if default_currency.nil?
				default_currency =  Currency.new({
					:abbreviation => 'NZD',
					:name => 'New Zealand Dollars',
					:symbol => 'NZ$',
					:exchange_rate => 1.00,
					:updated_at => Time.now,
					:update_every => 0,
					:is_default => 1
				})
				default_currency.save
			end
			default_currency
		end

		# Finds the currency with the specified abbrevation
		def [](abbreviation)
			if (abbreviation == 'NZD')
				Currency.default
			else
				Currency.find_by_abbreviation(abbreviation)
			end
		end
	end
end
