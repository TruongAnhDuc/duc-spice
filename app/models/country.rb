# Represents a country for the purposes of shipping.

class Country < ActiveRecord::Base
	belongs_to :shipping_zone

	class << self
		# This is now a hash because of the double-serialising done by the zone editor.
		# The key is the value processed by gsub(/[^A-Za-z0-9]/, "_").downcase, because of
		# the way the zone editor works.
		# We should probably edit/reduce this list sometime.
		COUNTRIES = {
			'afghanistan'				=>	'Afghanistan',
			'albania'					=>	'Albania',
			'algeria'					=>	'Algeria',
			'american_samoa'			=>	'American Samoa',
			'andorra'					=>	'Andorra',
			'angola'					=>	'Angola',
			'anguilla'					=>	'Anguilla',
			'antarctica'				=>	'Antarctica',
			'antigua_and_barbuda'		=>	'Antigua And Barbuda',
			'argentina'					=>	'Argentina',
			'armenia'					=>	'Armenia',
			'aruba'						=>	'Aruba',
			'australia'					=>	'Australia',
			'austria'					=>	'Austria',
			'azerbaijan'				=>	'Azerbaijan',
			'bahamas'					=>	'Bahamas',
			'bahrain'					=>	'Bahrain',
			'bangladesh'				=>	'Bangladesh',
			'barbados'					=>	'Barbados',
			'belarus'					=>	'Belarus',
			'belgium'					=>	'Belgium',
			'belize'					=>	'Belize',
			'benin'						=>	'Benin',
			'bermuda'					=>	'Bermuda',
			'bhutan'					=>	'Bhutan',
			'bolivia'					=>	'Bolivia',
			'bosnia_and_herzegowina'	=>	'Bosnia and Herzegowina',
			'botswana'					=>	'Botswana',
			'bouvet_island'				=>	'Bouvet Island',
			'brazil'					=>	'Brazil',
			'british_indian_ocean_territory'	=>	'British Indian Ocean Territory',
			'brunei_darussalam'			=>	'Brunei Darussalam',
			'bulgaria'					=>	'Bulgaria',
			'burkina_faso'				=>	'Burkina Faso',
			'burma'						=>	'Burma',
			'burundi'					=>	'Burundi',
			'cambodia'					=>	'Cambodia',
			'cameroon'					=>	'Cameroon',
			'canada'					=>	'Canada',
			'cape_verde'				=>	'Cape Verde',
			'cayman_islands'			=>	'Cayman Islands',
			'central_african_republic'	=>	'Central African Republic',
			'chad'						=>	'Chad',
			'chile'						=>	'Chile',
			'china'						=>	'China',
			'christmas_island'			=>	'Christmas Island',
			'cocos__keeling__islands'	=>	'Cocos (Keeling) Islands',
			'colombia'					=>	'Colombia',
			'comoros'					=>	'Comoros',
			'congo'						=>	'Congo',
			'congo__the_democratic_republic_of'	=>	'Congo, the Democratic Republic of',
			'cook_islands'				=>	'Cook Islands',
			'costa_rica'				=>	'Costa Rica',
			'cote_d_ivoire'				=>	'Cote d\'Ivoire',
			'croatia'					=>	'Croatia',
			'cuba'						=>	'Cuba',
			'cyprus'					=>	'Cyprus',
			'czech_republic'			=>	'Czech Republic',
			'denmark'					=>	'Denmark',
			'djibouti'					=>	'Djibouti',
			'dominica'					=>	'Dominica',
			'dominican_republic'		=>	'Dominican Republic',
			'east_timor'				=>	'East Timor',
			'ecuador'					=>	'Ecuador',
			'egypt'						=>	'Egypt',
			'el_salvador'				=>	'El Salvador',
			'england'					=>	'England',
			'equatorial_guinea'			=>	'Equatorial Guinea',
			'eritrea'					=>	'Eritrea',
			'estonia'					=>	'Estonia',
			'ethiopia'					=>	'Ethiopia',
			'falkland_islands'			=>	'Falkland Islands',
			'faroe_islands'				=>	'Faroe Islands',
			'fiji'						=>	'Fiji',
			'finland'					=>	'Finland',
			'france'					=>	'France',
			'french_guiana'				=>	'French Guiana',
			'french_polynesia'			=>	'French Polynesia',
			'french_southern_territories'	=>	'French Southern Territories',
			'gabon'						=>	'Gabon',
			'gambia'					=>	'Gambia',
			'georgia'					=>	'Georgia',
			'germany'					=>	'Germany',
			'ghana'						=>	'Ghana',
			'gibraltar'					=>	'Gibraltar',
			'great_britain'				=>	'Great Britain',
			'greece'					=>	'Greece',
			'greenland'					=>	'Greenland',
			'grenada'					=>	'Grenada',
			'guadeloupe'				=>	'Guadeloupe',
			'guam'						=>	'Guam',
			'guatemala'					=>	'Guatemala',
			'guinea'					=>	'Guinea',
			'guinea_bissau'				=>	'Guinea-Bissau',
			'guyana'					=>	'Guyana',
			'haiti'						=>	'Haiti',
			'heard_and_mc_donald_islands'	=>	'Heard and Mc Donald Islands',
			'honduras'					=>	'Honduras',
			'hong_kong'					=>	'Hong Kong',
			'hungary'					=>	'Hungary',
			'iceland'					=>	'Iceland',
			'india'						=>	'India',
			'indonesia'					=>	'Indonesia',
			'ireland'					=>	'Ireland',
			'israel'					=>	'Israel',
			'italy'						=>	'Italy',
			'iran'						=>	'Iran',
			'iraq'						=>	'Iraq',
			'jamaica'					=>	'Jamaica',
			'japan'						=>	'Japan',
			'jordan'					=>	'Jordan',
			'kazakhstan'				=>	'Kazakhstan',
			'kenya'						=>	'Kenya',
			'kiribati'					=>	'Kiribati',
			'korea__republic_of'		=>	'Korea, Republic of',
			'korea__south_'				=>	'Korea (South)',
			'kuwait'					=>	'Kuwait',
			'kyrgyzstan'				=>	'Kyrgyzstan',
			'lao_people_s_democratic_republic'	=>	'Lao People\'s Democratic Republic',
			'latvia'					=>	'Latvia',
			'lebanon'					=>	'Lebanon',
			'lesotho'					=>	'Lesotho',
			'liberia'					=>	'Liberia',
			'liechtenstein'				=>	'Liechtenstein',
			'lithuania'					=>	'Lithuania',
			'luxembourg'				=>	'Luxembourg',
			'macau'						=>	'Macau',
			'macedonia'					=>	'Macedonia',
			'madagascar'				=>	'Madagascar',
			'malawi'					=>	'Malawi',
			'malaysia'					=>	'Malaysia',
			'maldives'					=>	'Maldives',
			'mali'						=>	'Mali',
			'malta'						=>	'Malta',
			'marshall_islands'			=>	'Marshall Islands',
			'martinique'				=>	'Martinique',
			'mauritania'				=>	'Mauritania',
			'mauritius'					=>	'Mauritius',
			'mayotte'					=>	'Mayotte',
			'mexico'					=>	'Mexico',
			'micronesia__federated_states_of'	=>	'Micronesia, Federated States of',
			'moldova__republic_of'		=>	'Moldova, Republic of',
			'monaco'					=>	'Monaco',
			'mongolia'					=>	'Mongolia',
			'montserrat'				=>	'Montserrat',
			'morocco'					=>	'Morocco',
			'mozambique'				=>	'Mozambique',
			'myanmar'					=>	'Myanmar',
			'namibia'					=>	'Namibia',
			'nauru'						=>	'Nauru',
			'nepal'						=>	'Nepal',
			'netherlands'				=>	'Netherlands',
			'netherlands_antilles'		=>	'Netherlands Antilles',
			'new_caledonia'				=>	'New Caledonia',
			'new_zealand'				=>	'New Zealand',
			'nicaragua'					=>	'Nicaragua',
			'niger'						=>	'Niger',
			'nigeria'					=>	'Nigeria',
			'niue'						=>	'Niue',
			'norfolk_island'			=>	'Norfolk Island',
			'northern_ireland'			=>	'Northern Ireland',
			'northern_mariana_islands'	=>	'Northern Mariana Islands',
			'norway'					=>	'Norway',
			'oman'						=>	'Oman',
			'pakistan'					=>	'Pakistan',
			'palau'						=>	'Palau',
			'panama'					=>	'Panama',
			'papua_new_guinea'			=>	'Papua New Guinea',
			'paraguay'					=>	'Paraguay',
			'peru'						=>	'Peru',
			'philippines'				=>	'Philippines',
			'pitcairn'					=>	'Pitcairn',
			'poland'					=>	'Poland',
			'portugal'					=>	'Portugal',
			'puerto_rico'				=>	'Puerto Rico',
			'qatar'						=>	'Qatar',
			'reunion'					=>	'Reunion',
			'romania'					=>	'Romania',
			'russia'					=>	'Russia',
			'rwanda'					=>	'Rwanda',
			'saint_kitts_and_nevis'		=>	'Saint Kitts and Nevis',
			'saint_lucia'				=>	'Saint Lucia',
			'saint_vincent_and_the_grenadines'	=>	'Saint Vincent and the Grenadines',
			'samoa__independent_'		=>	'Samoa (Independent)',
			'san_marino'				=>	'San Marino',
			'sao_tome_and_principe'		=>	'Sao Tome and Principe',
			'saudi_arabia'				=>	'Saudi Arabia',
			'scotland'					=>	'Scotland',
			'senegal'					=>	'Senegal',
			'serbia_and_montenegro'		=>	'Serbia and Montenegro',
			'seychelles'				=>	'Seychelles',
			'sierra_leone'				=>	'Sierra Leone',
			'singapore'					=>	'Singapore',
			'slovakia'					=>	'Slovakia',
			'slovenia'					=>	'Slovenia',
			'solomon_islands'			=>	'Solomon Islands',
			'somalia'					=>	'Somalia',
			'south_africa'				=>	'South Africa',
			'south_georgia_and_the_south_sandwich_islands'	=>	'South Georgia and the South Sandwich Islands',
			'south_korea'				=>	'South Korea',
			'spain'						=>	'Spain',
			'sri_lanka'					=>	'Sri Lanka',
			'st__helena'				=>	'St. Helena',
			'st__pierre_and_miquelon'	=>	'St. Pierre and Miquelon',
			'suriname'					=>	'Suriname',
			'svalbard_and_jan_mayen_islands'	=>	'Svalbard and Jan Mayen Islands',
			'swaziland'					=>	'Swaziland',
			'sweden'					=>	'Sweden',
			'switzerland'				=>	'Switzerland',
			'taiwan'					=>	'Taiwan',
			'tajikistan'				=>	'Tajikistan',
			'tanzania'					=>	'Tanzania',
			'thailand'					=>	'Thailand',
			'togo'						=>	'Togo',
			'tokelau'					=>	'Tokelau',
			'tonga'						=>	'Tonga',
			'trinidad'					=>	'Trinidad',
			'trinidad_and_tobago'		=>	'Trinidad and Tobago',
			'tunisia'					=>	'Tunisia',
			'turkey'					=>	'Turkey',
			'turkmenistan'				=>	'Turkmenistan',
			'turks_and_caicos_islands'	=>	'Turks and Caicos Islands',
			'tuvalu'					=>	'Tuvalu',
			'uganda'					=>	'Uganda',
			'ukraine'					=>	'Ukraine',
			'united_arab_emirates'		=>	'United Arab Emirates',
			'united_kingdom'			=>	'United Kingdom',
			'united_states'				=>	'United States',
			'united_states_minor_outlying_islands'	=>	'United States Minor Outlying Islands',
			'uruguay'					=>	'Uruguay',
			'uzbekistan'				=>	'Uzbekistan',
			'vanuatu'					=>	'Vanuatu',
			'vatican_city_state__holy_see_'	=>	'Vatican City State (Holy See)',
			'venezuela'					=>	'Venezuela',
			'viet_nam'					=>	'Viet Nam',
			'virgin_islands__british_'	=>	'Virgin Islands (British)',
			'virgin_islands__u_s__'		=>	'Virgin Islands (U.S.)',
			'wales'						=>	'Wales',
			'wallis_and_futuna_islands'	=>	'Wallis and Futuna Islands',
			'western_sahara'			=>	'Western Sahara',
			'yemen'						=>	'Yemen',
			'zambia'					=>	'Zambia',
			'zimbabwe'					=>	'Zimbabwe'
		} unless const_defined?('COUNTRIES')

		# Get the list of countries
		def countries
			COUNTRIES
		end

		# Get the list of countries not assigned to a ShippingZone
		def free_countries
			Country.countries.values - ShippingZone.find(:all, :include => :countries).collect { |zone| zone.countries.values.collect { |country| country.name } }.flatten
		end
	end
end