#!/usr/bin/env ruby
# encoding: utf-8

require 'sequel'
require 'erubis'
require 'sinatra'
require 'json'

DB = Sequel.sqlite("paf.db", :encoding => 'utf-8')

require './lib/entry'

helpers do
  def path(s)
    File.join(env["HTTP_SCRIPT_NAME"] || request.script_name, s)
  end
end

get '/' do
  erb :front
end

get '/flora' do
  @entries = Entry.where(:ranking => 'family')
  erb :entry
end

get '/lower' do
  @entry = Entry[:paf_id => params[:id][/\d.+/]]
  erb :_lower, :locals => { :entry => @entry }, :layout => false
end

get '/introduction' do
  erb :introduction
end

get '/references' do
  erb :references
end

get '/contact' do
  erb :contact
end

get '/search' do
  erb :search
end

get '/children' do
  Entry[:paf_id => params[:paf]].children.all.to_json
end

get '/entry' do
  @entry = Entry[:paf_id => params[:id][/\d.+/]]
  erb :_entry, :layout => false
end

get '/results' do
  entries = Entry.where(Sequel.ilike(:name, "%#{params[:name]}%")).all
  s_entries = Synonym.where(Sequel.ilike(:name, "%#{params[:name]}%")).all.map { |s| s.entry }
  @results = (entries + s_entries).uniq
  erb :results
end

get '/distribution' do
  erb :distributions
end

get '/:id' do |id|
  @entries = Entry.where(:ranking => 'family')
  @entry = Entry.find(:paf_id => id)
  if params[:save]
    @entry.save
  end
  @entry ? erb(:entry) : pass
end

set :views, File.dirname(__FILE__) + "/views"
set :public, File.dirname(__FILE__) + "/public"

enable :run if $0 == __FILE__

