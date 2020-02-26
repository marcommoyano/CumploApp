class SbifService
  include HTTParty

  base_uri 'http://api.sbif.cl'

  def initialize
    @api_key = ENV['SBIF_API_KEY']
    @response = nil
  end

  def currency_duo(first_date, second_date)
    resource = %w(uf dolar)
    first_date = first_date.to_date
    second_date = second_date.to_date

    recipient = resource.map do |r|
      range(r,
            first_date.year,
            first_date.month,
            second_date.year,
            second_date.month)
    end
    merge_recipient(recipient)
  end

  def merge_recipient(recipient)
    result_array = recipient.first.map do |first_hash|
      recipient.second.each do |second_hash|
        if first_hash[:date] == second_hash[:date]
          first_hash[:dolar] = second_hash[:dolar]
          break
        end
      end
      first_hash
    end
    result_array
  end

  def range(resource, year, month, year2, month2)
    @response = self.class.get("/api-sbifv3/recursos_api/#{resource}/periodo/#{year}/#{month}/#{year2}/#{month2}?apikey=#{@api_key}&formato=xml")
    @response = response(resource)
    data(resource)
  end

  def response(resource)
    resource =
      case resource
      when 'uf'
        symbolize_keys_deep!(@response)[:indicadores_financieros][:u_fs][:uf]
      when 'dolar'
        symbolize_keys_deep!(@response)[:indicadores_financieros][:dolares][:dolar]
      end
    resource
  end

  def data(resource)
    data = @response.map do |x|
      { date: x['Fecha'], resource.to_sym => value_format(x['Valor']) }
    end
    data
  end

  def value_format(value)
    value = value.tr('.', '').tr(',', '.').to_f
    value
  end

  def symbolize_keys_deep!(h)
    h.keys.each do |k|
      ks    = k.underscore.to_sym
      h[ks] = h.delete k
      symbolize_keys_deep! h[ks] if h[ks].is_a? Hash
    end
    h
  end
end
