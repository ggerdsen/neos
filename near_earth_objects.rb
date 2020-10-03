require 'faraday'
require 'figaro'
require 'pry'
require 'json'
# Load ENV vars via Figaro
Figaro.application = Figaro::Application.new(environment: 'production', path: File.expand_path('../config/application.yml', __FILE__))
Figaro.load

class NearEarthObjects
  def self.find_neos_by_date(date)
    @conn = api_connect(date)
    @asteroids_list_data = api_get_data
    parsed_asteroids_data = api_parse_data(date)
    largest_astroid_diameter = largest_asteroid(parsed_asteroids_data)
    total_number_of_astroids = parsed_asteroids_data.count
    formatted_asteroid_data = format_data(parsed_asteroids_data)
  
    {
      astroid_list: formatted_asteroid_data,
      biggest_astroid: largest_astroid_diameter,
      total_number_of_astroids: total_number_of_astroids
    }
  
  end
  
  def self.api_connect(date)
    Faraday.new(
      url: 'https://api.nasa.gov',
      params: { start_date: date, api_key: ENV['nasa_api_key']}
    )
  end
  
  def self.api_get_data
    @conn.get('/neo/rest/v1/feed')
  end
  
  def self.api_parse_data(date)
    JSON.parse(@asteroids_list_data.body, symbolize_names: true)[:near_earth_objects][:"#{date}"]
  end
  
  def self.largest_asteroid(parsed_asteroids_data)
    parsed_asteroids_data.map do |astroid|
      astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i
    end.max { |a,b| a<=> b}
  end
  
  def self.format_data(parsed_asteroids_data)
    parsed_asteroids_data.map do |astroid|
      {
        name: astroid[:name],
        diameter: "#{astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i} ft",
        miss_distance: "#{astroid[:close_approach_data][0][:miss_distance][:miles].to_i} miles"
      }
    end
  end
end
