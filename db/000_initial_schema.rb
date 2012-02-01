#
# I have a feeling this is not going to be used ever again (which is a good thing). 'schema.rb' is
# the Rails 1.2 version of this file (I think...), and any case, is in Ruby (DBMS agnostic). Also,
# schema.rb is for db version 4 - from then on migrations can simply be applied (during install,
# for example).
#
class ProductOptionsChanges < ActiveRecord::Migration
	def self.up
		sql_code = <<_SQL
-- phpMyAdmin SQL Dump
-- version 2.8.1
-- http://www.phpmyadmin.net
--
-- Host: localhost
-- Generation Time: Jul 20, 2006 at 02:14 PM
-- Server version: 4.0.20
-- PHP Version: 4.3.2
--
-- Initial version of RocketCart database schema
-- (as of 2006-12-11 - db:migrate version 3)
--
--
-- Database: `rocketcart_dev`
--

--
-- CHANGE THIS BEFORE RUNNING!
--

USE rocketcart_dev;

-- --------------------------------------------------------

--
-- Table structure for table `addresses`
--

DROP TABLE IF EXISTS `addresses`;
CREATE TABLE IF NOT EXISTS `addresses` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(64) default NULL,
  `address` varchar(128) default NULL,
  `city` varchar(128) default NULL,
  `postcode` varchar(32) default NULL,
  `country` varchar(64) default NULL,
  PRIMARY KEY  (`id`),
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `categories`
--

DROP TABLE IF EXISTS `categories`;
CREATE TABLE IF NOT EXISTS `categories` (
  `id` int(11) NOT NULL auto_increment,
  `parent_id` int(11) default NULL,
  `lft` int(11) default NULL,
  `rgt` int(11) default NULL,
  `name` varchar(64) default NULL,
  `filename` varchar(48) default NULL,
  `path` varchar(255) default NULL,
  `description` text,
  `title` varchar(128) default NULL,
  `meta_keywords` text,
  `meta_description` text,
  PRIMARY KEY  (`id`),
  KEY `parent_id` (`parent_id`),
  KEY `lft` (`lft`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `categories_products`
--

DROP TABLE IF EXISTS `categories_products`;
CREATE TABLE IF NOT EXISTS `categories_products` (
  `category_id` int(11) NOT NULL default '0',
  `product_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`category_id`,`product_id`),
  KEY `category_id` (`category_id`),
  KEY `product_id` (`product_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `countries`
--

DROP TABLE IF EXISTS `countries`;
CREATE TABLE IF NOT EXISTS `countries` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(64) NOT NULL default '',
  `shipping_zone_id` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `country_name` (`name`),
  KEY `country_zone` (`shipping_zone_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `currencies`
--

DROP TABLE IF EXISTS `currencies`;
CREATE TABLE IF NOT EXISTS `currencies` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(32) default NULL,
  `abbreviation` varchar(8) default NULL,
  `symbol` varchar(8) default '$',
  `exchange_rate` float(6,4) NOT NULL default '1.0000',
  `updated_at` datetime default NULL,
  `update_every` int(11) NOT NULL default '86400',
  `is_default` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `abbr` (`abbreviation`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `images`
--

DROP TABLE IF EXISTS `images`;
CREATE TABLE IF NOT EXISTS `images` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(64) default NULL,
  `product_id` int(11) NOT NULL default '0',
  `thumbnail_of` int(11) default NULL,
  `filename` varchar(255) NOT NULL default '',
  `content_type` varchar(64) default NULL,
  `data` longblob,
  `width` int(11) NOT NULL default '0',
  `height` int(11) NOT NULL default '0',
  `caption` text,
  `display_order` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `product_id` (`product_id`),
  KEY `thumbnail_of` (`thumbnail_of`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `line_items`
--

DROP TABLE IF EXISTS `line_items`;
CREATE TABLE IF NOT EXISTS `line_items` (
  `id` int(11) NOT NULL auto_increment,
  `product_id` int(11) NOT NULL default '0',
  `order_id` int(11) NOT NULL default '0',
  `quantity` int(11) NOT NULL default '1',
  `unit_price` decimal(10,2) NOT NULL default '0.00',
  `options` text,
  PRIMARY KEY  (`id`),
  KEY `product_id` (`product_id`),
  KEY `order_id` (`order_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `option_values`
--

DROP TABLE IF EXISTS `option_values`;
CREATE TABLE IF NOT EXISTS `option_values` (
  `id` int(11) NOT NULL auto_increment,
  `option_id` int(11) NOT NULL default '0',
  `value` text,
  `position` int(11) NOT NULL default '0',
  `extra_cost` float NOT NULL default '0',
  `extra_weight` float NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `option_id` (`option_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `options`
--

DROP TABLE IF EXISTS `options`;
CREATE TABLE IF NOT EXISTS `options` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(64) default NULL,
  `type` varchar(64) default NULL,
  `default_value` text,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `orders`
--

DROP TABLE IF EXISTS `orders`;
CREATE TABLE IF NOT EXISTS `orders` (
  `id` int(11) NOT NULL auto_increment,
  `user_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `shipping_email` varchar(128) default NULL,
  `shipping_address_id` int(11) default NULL,
  `subtotal` decimal(10,2) NOT NULL default '0.00',
  `shipping_cost` decimal(10,2) default NULL,
  `total` decimal(10,2) NOT NULL default '0.00',
  `shipping_zone_id` int(11) default NULL,
  `status` varchar(16) NOT NULL default 'in_progress',
  `delivery_address_id` int(11) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `plugin_parameters`
--

DROP TABLE IF EXISTS `plugin_parameters`;
CREATE TABLE IF NOT EXISTS `plugin_parameters` (
  `id` int(11) NOT NULL auto_increment,
  `plugin_id` int(11) default NULL,
  `name` varchar(64) default NULL,
  `value` text,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `plugins`
--

DROP TABLE IF EXISTS `plugins`;
CREATE TABLE IF NOT EXISTS `plugins` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(64) default NULL,
  `name` varchar(64) default NULL,
  `description` text,
  `script` varchar(128) default NULL,
  `config` varchar(128) default NULL,
  `active` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `product_components`
--

DROP TABLE IF EXISTS `product_components`;
CREATE TABLE IF NOT EXISTS `product_components` (
  `id` int(11) NOT NULL auto_increment,
  `parent_id` int(11) NOT NULL default '0',
  `child_id` int(11) NOT NULL default '0',
  `quantity` int(11) NOT NULL default '1',
  `position` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`),
  KEY `parent_id` (`parent_id`),
  KEY `child_id` (`child_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `product_options`
--

DROP TABLE IF EXISTS `product_options`;
CREATE TABLE IF NOT EXISTS `product_options` (
  `id` int(11) NOT NULL auto_increment,
  `option_id` int(11) NOT NULL default '0',
  `product_id` int(11) NOT NULL default '0',
  `position` int(11) NOT NULL default '0',
  `default_value` text,
  `values` text,
  PRIMARY KEY  (`id`),
  KEY `option_id` (`option_id`),
  KEY `product_id` (`product_id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `products`
--

DROP TABLE IF EXISTS `products`;
CREATE TABLE IF NOT EXISTS `products` (
  `id` int(11) NOT NULL auto_increment,
  `type` varchar(32) default NULL,
  `product_code` varchar(16) default NULL,
  `product_name` varchar(64) default NULL,
  `description` text,
  `base_price` decimal(10,2) NOT NULL default '0.00',
  `discount` decimal(10,2) NOT NULL default '0.00',
  `base_weight` decimal(8,3) NOT NULL default '0.000',
  `available` int(11) NOT NULL default '1',
  `featured_in` int(11) default NULL,
  `featured_product_id` int(11) default NULL,
  `featured_weighting` int(11) default NULL,
  `featured_all_levels` int(11) default NULL,
  `meta_keywords` text,
  `meta_description` text,
  `image_alt_tag` text,
  `page_title` varchar(100),
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `schema_info`
--

DROP TABLE IF EXISTS `schema_info`;
CREATE TABLE IF NOT EXISTS `schema_info` (
  `version` int(11) default NULL
) TYPE=MyISAM;

-- --------------------------------------------------------

--
-- Table structure for table `shipping_zones`
--

DROP TABLE IF EXISTS `shipping_zones`;
CREATE TABLE IF NOT EXISTS `shipping_zones` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(64) NOT NULL default '',
  `per_item` decimal(10,2) NOT NULL default '0.00',
  `per_kg` decimal(10,2) NOT NULL default '0.00',
  `flat_rate` decimal(10,2) NOT NULL default '0.00',
  `default_zone` int(11) NOT NULL default '0',
  `position` int(11) NOT NULL default '0',
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `static_pages`
--

DROP TABLE IF EXISTS `static_pages`;
CREATE TABLE IF NOT EXISTS `static_pages` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(128) default NULL,
  `path` varchar(255) default NULL,
  `title` varchar(128) default NULL,
  `body` text,
  `meta_keywords` text,
  `meta_description` text,
  PRIMARY KEY  (`id`),
  KEY `path` (`path`)
) TYPE=InnoDB;

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL auto_increment,
  `user_level` int(11) NOT NULL default '0',
  `first_name` varchar(32) default NULL,
  `last_name` varchar(32) default NULL,
  `email` varchar(128) NOT NULL default '',
  `hashed_password` varchar(64) default NULL,
  PRIMARY KEY  (`id`)
) TYPE=InnoDB;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `categories`
--
ALTER TABLE `categories`
  ADD CONSTRAINT `categories_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `categories_products`
--
ALTER TABLE `categories_products`
  ADD CONSTRAINT `categories_products_ibfk_1` FOREIGN KEY (`category_id`) REFERENCES `categories` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `categories_products_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;

--
-- Constraints for table `countries`
--
ALTER TABLE `countries`
  ADD CONSTRAINT `countries_ibfk_1` FOREIGN KEY (`shipping_zone_id`) REFERENCES `shipping_zones` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `images`
--
ALTER TABLE `images`
  ADD CONSTRAINT `images_ibfk_1` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `images_ibfk_2` FOREIGN KEY (`thumbnail_of`) REFERENCES `images` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `line_items`
--
ALTER TABLE `line_items`
  ADD CONSTRAINT `line_items_ibfk_1` FOREIGN KEY (`order_id`) REFERENCES `orders` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `line_items_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`);

--
-- Constraints for table `option_values`
--
ALTER TABLE `option_values`
  ADD CONSTRAINT `option_values_ibfk_1` FOREIGN KEY (`option_id`) REFERENCES `options` (`id`);

--
-- Constraints for table `orders`
--
ALTER TABLE `orders`
  ADD CONSTRAINT `orders_ibfk_1` FOREIGN KEY (`shipping_address_id`) REFERENCES `addresses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;
  ADD CONSTRAINT `orders_ibfk_2` FOREIGN KEY (`delivery_address_id`) REFERENCES `addresses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `product_components`
--
ALTER TABLE `product_components`
  ADD CONSTRAINT `product_components_ibfk_1` FOREIGN KEY (`parent_id`) REFERENCES `products` (`id`),
  ADD CONSTRAINT `product_components_ibfk_2` FOREIGN KEY (`child_id`) REFERENCES `products` (`id`);

--
-- Constraints for table `product_options`
--
ALTER TABLE `product_options`
  ADD CONSTRAINT `product_options_ibfk_1` FOREIGN KEY (`option_id`) REFERENCES `options` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `product_options_ibfk_2` FOREIGN KEY (`product_id`) REFERENCES `products` (`id`) ON DELETE CASCADE;
_SQL
		sql_code.split(";\n").each do |statement|
			execute statement
		end
	end
end
