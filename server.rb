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

def total_actors
  total = db_connection do |conn|
    sql_query = "SELECT COUNT(*) AS total FROM actors"
    conn.exec(sql_query)
  end
  total.first['total'].to_f
end

def total_movies
  total = db_connection do |conn|
    sql_query = "SELECT COUNT(*) AS total FROM movies"
    conn.exec(sql_query)
  end
  total.first['total'].to_f
end

def total_pages_actors(per_page)
  (total_actors / per_page).ceil
end

def total_pages_movies(per_page)
  (total_movies / per_page).ceil
end

get '/actors' do

@page = params['page'].to_i

if @page < 2
  @page = 1
elsif @page > total_pages_actors(20)
  @page = total_pages_actors(20)
end

if @page == 1
  @offset = 0
else
  @offset = (@page - 1) * 20
end

@total_pages = total_pages_actors(20)

@actors = db_connection do |conn|
  sql_query = 'SELECT * FROM actors ORDER BY name LIMIT 20 OFFSET ($1)'
  data = ["#{@offset}"]
  conn.exec(sql_query, data)
end

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

  @page = params['page'].to_i

  if @page < 2
    @page = 1
  elsif @page > total_pages_movies(20)
    @page = total_pages_movies(20)
  end

  if @page == 1
    @offset = 0
  else
    @offset = (@page - 1) * 20
  end

  @total_pages = total_pages_movies(20)

  order_by = params['order']
  if order_by == 'year'
    @movies = db_connection do |conn|
      sql_query = "SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
      FROM movies
      LEFT JOIN genres ON movies.genre_id = genres.id
      LEFT JOIN studios ON movies.studio_id = studios.id
      ORDER BY movies.year LIMIT 20 OFFSET ($1))"
      data = ["#{@offset}"]
      conn.exec(sql_query, data)
    end

  elsif order_by == 'rating'
    @movies = db_connection do |conn|
      sql_query = 'SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
      FROM movies
      LEFT JOIN genres ON movies.genre_id = genres.id
      LEFT JOIN studios ON movies.studio_id = studios.id
      ORDER BY movies.rating DESC NULLS LAST LIMIT 20 OFFSET ($1)'
      data = ["#{@offset}"]
      conn.exec(sql_query, data)
    end

  else

    @movies = db_connection do |conn|
      sql_query = 'SELECT movies.id, movies.title, movies.year, movies.rating, genres.name AS genre, studios.name AS studio
      FROM movies
      LEFT JOIN genres ON movies.genre_id = genres.id
      LEFT JOIN studios ON movies.studio_id = studios.id
      ORDER BY movies.title LIMIT 20 OFFSET ($1)'
      data = ["#{@offset}"]
      conn.exec(sql_query, data)
    end
  end
  erb :'movies/index'
end

get '/movies/:id' do
  @movie_id = params[:id]
  @movie_actors = db_connection do |conn|
    conn.exec("SELECT movies.id, movies.title, movies.rating, movies.year, genres.name AS genre, studios.name AS studio, actors.name AS actor, actors.id AS actor_id, cast_members.character
    FROM movies
    LEFT JOIN cast_members ON movies.id = cast_members.movie_id
    LEFT JOIN actors ON cast_members.actor_id = actors.id
    LEFT JOIN genres ON movies.genre_id = genres.id
    LEFT JOIN studios ON movies.studio_id = studios.id
    WHERE movies.id = '#{@movie_id}'")
  end
    erb :'movies/show'
end
