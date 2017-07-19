# frozen_string_literal: true
require 'scraped'
require 'table_unspanner'

class RemoveFootnotes < Scraped::Response::Decorator
  def body
    Nokogiri::HTML(super).tap { |doc| doc.css('sup').remove }.to_s
  end
end
