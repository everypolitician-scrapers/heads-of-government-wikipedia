#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'require_all'
require 'scraped'
require 'scraperwiki'
require 'wikidata_ids_decorator'

require_rel 'lib'

def scraped(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

class CountriesList < Scraped::HTML
  decorator WikidataIdsDecorator::Links
  decorator UnspanAllTables
  decorator RemoveFootnotes

  field :countries do
    table.xpath('.//tr[td]').map do |tr|
      fragment(tr => CountryRow).to_h
    end
  end

  private

  def table
    noko.xpath('//table[contains(.//th[1], "State")]')
  end
end

class CountryRow < Scraped::HTML
  field :id do
    noko.at_css('th a/@wikidata').text
  end

  field :name do
    noko.at_css('th a').text.tidy
  end

  field :office do
    hog_links.first.text.tidy
  end

  field :office_id do
    hog_links.first.attr('wikidata')
  end

  field :holder do
    hog_links.last.text.tidy
  end

  field :holder_id do
    hog_links.last.attr('wikidata')
  end

  private

  def td
    noko.css('td')
  end

  def hog_links
    td[-1].css('a')
  end
end

url = 'https://en.wikipedia.org/wiki/List_of_current_heads_of_state_and_government'
data = scraped(url => CountriesList).countries
data.each { |mem| puts mem.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h } if ENV['MORPH_DEBUG']

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite(%i(id office_id holder_id), data)
