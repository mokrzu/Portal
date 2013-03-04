require 'rubygems'
require 'sinatra'
require 'mongo'

include Mongo

begin
    @client = Mongo::Connection.new('localhost', 27017)
    @database = @client['portal']

    set :collection, @database['urls']
rescue => exception
    if exception.class == Mongo::ConnectionFailure
        set :db_server, :down
    end
else 
    set :db_server, :running
end


helpers do
    
    # Create and save in database, shortcut for given adress
    #
    # url - website adress
    #
    # Examples:
    #
    #   shortcut("http://tomdoc.org/")
    #   => "http://localhost:9393/FNQZJA"
    #
    # Returns link with shortcut
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

# Filter: check if mongo server is running
before do
    next if request.path_info == "/error_page"
    if settings.db_server == :down
        redirect to("/error_page")
    end
end


get '/' do
    erb :index
end

get '/error_page' do
    erb :error_page
end

get '/all' do
    @all = settings.collection.find().to_a
    @adresses = Array.new

    @all.each do |document|

        unless document['key'].nil? or document['adress'].nil?
            @adresses << document
        end
    end

    erb :list, :locals => {:list => @adresses}
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
