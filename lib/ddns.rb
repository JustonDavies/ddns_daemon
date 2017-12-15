class DDNS
  
#-- Local Constants ----------------------------------------------------------------------------------------------------
  DOMAINS = CONFIGURATION['ddns']['domains']

#== Public Methods =====================================================================================================
  public
  def self.external_ip_address
    #_external_ip = `LANG=c ifconfig | grep -B1 "inet addr" |awk '{ if ( $1 == "inet" ) { print $2 } else if ( $2 == "Link" ) { printf "%s:" ,$1 } }' |awk -F: '{ print $1 ": " $3 }'` #required sudo for ifconfig
    _external_ip = `dig +short myip.opendns.com @resolver1.opendns.com`
    _external_ip
  end

  def self.update_dns_records
    _current_external_ip = self.external_ip_address.to_s

    DOMAINS.each do |tracked_domain|
      LOGGER.info "Starting updates for #{tracked_domain['name']}"

      _domain = Gandi::Domain.get(name: tracked_domain['name'].to_s)

      unless _domain
        LOGGER.info "Unable to find domain for #{tracked_domain['name']}"
        next
      end

      _zone_uuid = _domain['zone_uuid']

      tracked_domain['records'].each do |tracked_record|
        _full_dns_name = "#{tracked_record['name']}.#{tracked_domain['name']}"
        _full_dns_name = tracked_domain['name'] if tracked_record['name'] == '@'

        _current_dns_answer = `dig +short #{_full_dns_name}`.to_s
        _dns_query_incorrect = _current_dns_answer != _current_external_ip

        _record = Gandi::Record.get(zone_uuid: _zone_uuid, name: tracked_record['name'], type: tracked_record['type'])
        _remote_record_incorrect = _record == nil or _record[:values] == nil and _record[:values].first != _current_external_ip

        if _dns_query_incorrect or _remote_record_incorrect
          LOGGER.info "Record update required for #{_full_dns_name}: Set #{_current_external_ip}"
          _success = Gandi::Record.create_or_update(
            zone_uuid: _zone_uuid,
            name: tracked_record['name'],
            type: tracked_record['type'],
            values: [_current_external_ip]
          )
          LOGGER.info "Result: #{_success}"
        else
          LOGGER.info "No update required for #{_full_dns_name}: Current #{_current_dns_answer}"
        end
      end
    end
  end

#== Private Methods ====================================================================================================
  private

end
