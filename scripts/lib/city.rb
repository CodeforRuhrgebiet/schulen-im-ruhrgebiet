class City
  include ERB::Util

  def self.supported_cities
    city_values = []
    cities_as_yml = File.open("#{@@project_root}/supported_cities.yml")
    YAML::load(cities_as_yml).each { |city| city_values.push({ name: city['name'], city_name_in_postcode_file: city['city_name_in_postcode_file'] }) }
    city_values
  end

  # Instance Methods
  def initialize(open_data, city_values)
    @open_data = open_data
    @name = city_values[:name]
    @key = city_values[:name].downcase
    puts "# Initializing City: #{@name}"
    @postcodes = city_postcodes(city_values[:city_name_in_postcode_file])
    @schools = []
    @text = 'OMG, IT WORKS!!!!'
  end

  def fetch_schools!
    raw = @open_data.read_file('schuldaten.xml')
    doc = Nokogiri::XML(raw)
    xml_schools = doc.search('//Schule')
    school_count = xml_schools.size
    xml_schools.each_with_index do |school, index|
      puts "Searching for relevant Schools (#{index+1}/#{school_count})"
      if within_postcode?(school.css('PLZ').children.text)
        s = School.new(@open_data, school)
        @schools.push(s.as_feature)
      end
    end
  end

  def save_to_files!
    data = {type: 'FeatureCollection', features: @schools}
    File.open("#{geojson_directory}/#{@key}.geojson", 'w') { |file| file.print data.to_json }
    File.open("#{city_collection_directory}/#{@key}.md", 'w+') { |f| f.write(render) }
  end

  private

  def city_postcodes(key)
    @open_data.city_postcodes_by_key(key)
  end

  def within_postcode?(postcode)
    @postcodes.include?(postcode)
  end

  def render
    ERB.new(template).result(binding)
  end

  def geojson_directory
    "#{@@project_root}/js/cities"
  end

  def city_collection_directory
    "#{@@project_root}/_cities"
  end

  def template
    File.read("#{city_collection_directory}/_city.md.erb")
  end
end
