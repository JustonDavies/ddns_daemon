class Gandi
  require 'uri'
  require 'json'
  require 'net/http'
  require 'net/https'

#-- Local Constants ----------------------------------------------------------------------------------------------------
  API_URI = CONFIGURATION['gandi']['api_uri']
  API_TOKEN = CONFIGURATION['gandi']['api_token']

#-- Nested Classes -----------------------------------------------------------------------------------------------------
  class Domain
    def self.get(name:, inflate: true, scrub: true)
      _response = Gandi.api_get(path: "domains/#{name.to_s}")

      return nil unless _response.code.match? /20\d/

      _domain = JSON.parse(_response.body)
      _domain['zone'] = Gandi::Zone.get(zone_uuid: _domain['zone_uuid'], inflate: inflate, scrub: scrub) if inflate

      Gandi.scrub_response _domain if scrub

      _domain
    end
  end

  class Zone
    def self.get(zone_uuid:, inflate: true, scrub: true)
      _response = Gandi.api_get(path: "zones/#{zone_uuid.to_s}")

      return nil unless _response.code.match? /20\d/
      _zone = JSON.parse(_response.body)
      _zone['records'] = Gandi::Zone.records(zone_uuid: zone_uuid, scrub: scrub) if inflate

      Gandi.scrub_response _zone if scrub

      _zone
    end

    def self.records(zone_uuid:, scrub: true)
      _response = Gandi.api_get(path: "zones/#{zone_uuid.to_s}/records")

      return nil unless _response.code.match? /20\d/
      _records = JSON.parse(_response.body)

      _records.map! {|record| Gandi.scrub_response record; } if scrub

      #Nicer formatting
      _records.map! do |record|
        {
          name: record['rrset_name'],
          type: record['rrset_type'],
          ttl: record['rrset_ttl'],
          values: record['rrset_values']
        }
      end

      _records
    end
  end

  class Record
    def self.create(zone_uuid:, name:, type:, ttl: 300, values:)
      _response = Gandi.api_post(
        path: "zones/#{zone_uuid.to_s}/records",
        parameters: {
          rrset_name: name,
          rrset_type: type,
          rrset_ttl: ttl,
          rrset_values: values
        }
      )

      return false unless _response.code.match? /20\d/
      _record = JSON.parse(_response.body)

      return false unless _record['message'] == 'DNS Record Created'

      _record
    end

    def self.get(zone_uuid:, name:, type:, scrub: true)
      _response = Gandi.api_get(path: "zones/#{zone_uuid.to_s}/records/#{name}/#{type}")

      return nil unless _response.code.match? /20\d/
      _record = JSON.parse(_response.body)

      Gandi.scrub_response _record if scrub

      #Nicer formatting
      _record = {
        name: _record['rrset_name'],
        type: _record['rrset_type'],
        ttl: _record['rrset_ttl'],
        values: _record['rrset_values']
      }

      _record
    end

    def self.destroy(zone_uuid:, name:, type:)
      _response = Gandi.api_delete(path: "zones/#{zone_uuid.to_s}/records/#{name}/#{type}")

      return false unless _response.code.match? /20\d/
      #This returns nil instead of {message: Success}, completely inconsistent

      true
    end

    def self.create_or_update(zone_uuid:, name:, type:, ttl: 300, values:)
      #Delete record if exists
      unless self.get(zone_uuid: zone_uuid, name: name, type: type) == nil
        self.destroy(
          zone_uuid: zone_uuid,
          name: name,
          type: type
        )
      end

      # Create new record
      self.create(
        zone_uuid: zone_uuid,
        name: name,
        type: type,
        ttl: ttl,
        values: values
      )
    end
  end
#== Public Methods =====================================================================================================
  public

#== Private Methods ====================================================================================================
  private

#-- Helpers ----------
  def self.scrub_response(hash)
    hash.select! {|key, value| !key.to_s.include? 'href'}
  end

#-- API get/post ----------
  def self.api_get(path:)
    _uri = URI(API_URI + URI.escape(path))

    _request = Net::HTTP::Get.new(_uri.request_uri)
    _request.content_type = 'application/json'
    _request['X-Api-Key'] = API_TOKEN.to_s

    _options = {
      use_ssl: _uri.scheme == 'https',
    }

    _response = Net::HTTP.start(_uri.host, _uri.port, _options) { |socket| socket.request(_request) }

    return _response
  end

  def self.api_delete(path:)
    _uri = URI(API_URI + URI.escape(path))

    _request = Net::HTTP::Delete.new(_uri.request_uri)
    _request.content_type = 'application/json'
    _request['X-Api-Key'] = API_TOKEN.to_s

    _options = {
      use_ssl: _uri.scheme == 'https',
    }

    _response = Net::HTTP.start(_uri.host, _uri.port, _options) { |socket| socket.request(_request) }

    return _response
  end

  def self.api_post(path:, parameters:)
    _uri = URI(API_URI + URI.escape(path))

    _request = Net::HTTP::Post.new(_uri.request_uri)
    _request.content_type = 'application/json'
    _request['X-Api-Key'] = API_TOKEN.to_s
    _request.body = JSON.dump(parameters)

    _options = {
      use_ssl: _uri.scheme == 'https',
    }

    _response = Net::HTTP.start(_uri.host, _uri.port, _options) { |socket| socket.request(_request) }

    return _response
  end

  def self.api_patch(path:, parameters:)
    _uri = URI(API_URI + URI.escape(path))

    _request = Net::HTTP::Patch.new(_uri.request_uri)
    _request.content_type = 'application/json'
    _request['X-Api-Key'] = API_TOKEN.to_s
    _request.body = JSON.dump(parameters)

    _options = {
      use_ssl: _uri.scheme == 'https',
    }

    _response = Net::HTTP.start(_uri.host, _uri.port, _options) { |socket| socket.request(_request) }

    return _response
  end

  def self.api_put(path:, parameters:)
    _uri = URI(API_URI + URI.escape(path))

    _request = Net::HTTP::Put.new(_uri.request_uri)
    _request.content_type = 'application/json'
    _request['X-Api-Key'] = API_TOKEN.to_s
    _request.body = JSON.dump(parameters)

    _options = {
      use_ssl: _uri.scheme == 'https',
    }

    _response = Net::HTTP.start(_uri.host, _uri.port, _options) { |socket| socket.request(_request) }

    return _response
  end
end