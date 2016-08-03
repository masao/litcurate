#!/usr/bin/env ruby

require "rubygems"
require "bundler"

Bundler.require

module Mendeley
  class Connection
    def initialize(access_token = nil)
      @access_token = ENV["MENDELEY_ACCESS_TOKEN"]
      @access_token = access_token if access_token
      @base_url = "https://api.mendeley.com"
    end
    def get(path, params = {})
      conn = Faraday.new(url: @base_url)
      conn.authorization :Bearer, @access_token
      response = conn.get(path, params)
      response.body
    end
  end
end

if $0 == __FILE__
  #ENV["MENDELEY_ACCESS_TOKEN"]
  mendeley = Mendeley::Connection.new
  folder = ARGV[0]
  if folder.nil?
    p mendeley.get("/folders")
  else
    obj = mendeley.get(File.join("/folders", folder, "documents"))
    docs = JSON.load(obj)
    docs.each do |d|
      obj = mendeley.get(File.join("/documents/", d["id"]))
      doc = JSON.load(obj)
      puts [doc["authors"].first["last_name"], doc["year"]].join
    end
  end
end


