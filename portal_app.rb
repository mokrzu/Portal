require 'rubygems'
require 'sinatra'
require 'mongo'

include Mongo

@client = Mongo::Connection.new('localhost', 27017)
@database = @client['portal']

set :collection, @database['urls']

helpers do
    def shortcut(url)
        if params[:url] and not params[:url].empty?

            @existing_adress = settings.collection.find({'adress' => url}).to_a.first
            
            if @existing_adress.nil?
                begin 
                    hash = (0...6).map{(65 + rand(26)).chr}.join
                end while not settings.collection.find({'key' => hash}).to_a.empty?
    
                settings.collection.insert({'key' => hash, 'adress' => url})
            else
                hash = @existing_adress['key']
            end            

            "http://localhost:9393/#{hash}"
        end
    end
end

get '/' do
    erb :index
end

get '/:shortcut' do |short|
    @result = settings.collection.find({'key' => short}).to_a
    
    unless @result.empty?
        @url = @result.first['adress']
    else 
        @url = "/"
    end

    redirect @url
end

post '/' do
    erb :index 
end