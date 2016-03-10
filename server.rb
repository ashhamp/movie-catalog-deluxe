require "sinatra"
require "pg"
require 'pry'

configure :development do
  set :db_config, { dbname: "movies" }
end

configure :test do
  set :db_config, { dbname: "movies_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
  ensure
    connection.close
  end
end

get '/actors' do

  @actors = db_connection do |conn|
    conn.exec('SELECT name, id FROM actors ORDER BY name')
  end
  # binding.pry

  erb :'actors/index'
end

get '/actors/:id' do
  @actor_id = params[:id]
  @actor_movies = db_connection do |conn|
    conn.exec("SELECT actors.name, actors.id AS actor_id, movies.title, movies.id AS movie_id, cast_members.character
    FROM cast_members JOIN actors ON cast_members.actor_id = actors.id
    JOIN movies ON cast_members.movie_id = movies.id
    WHERE actors.id = '#{@actor_id}'" )
  end

  erb :'actors/show'
end

get '/movies' do
  @movies = db_connection do |conn|
    conn.exec('SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
    FROM movies
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    ORDER BY movies.title;')
  end
  # binding.pry
  erb :'movies/index'
end

get '/movies/:id' do
  @movie_id = params[:id]
  @movie_actors = db_connection do |conn|
    conn.exec("SELECT movies.id, movies.title, movies.rating, movies.year, genres.name AS genre, studios.name AS studio, actors.name AS actor, actors.id AS actor_id, cast_members.character
    FROM movies
    JOIN cast_members ON movies.id = cast_members.movie_id
    JOIN actors ON cast_members.actor_id = actors.id
    JOIN genres ON movies.genre_id = genres.id
    JOIN studios ON movies.studio_id = studios.id
    WHERE movies.id = '#{@movie_id}'")
  end
    erb :'movies/show'

end
