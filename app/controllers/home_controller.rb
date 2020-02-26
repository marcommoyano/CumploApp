class HomeController < ApplicationController
  before_action :validate_date, only: [:search]
  
  def index; end

  def search
    @min_dolar = 999999.0
    @max_dolar = -1.0
    suma_dolar = 0.0
    @min_uf = 999999.0
    @max_uf = -1.0
    suma_uf = 0.0
    first_date = set_params[:first_date].to_date
    second_date = set_params[:second_date].to_date

    year = first_date.year
    month = first_date.month
    day = first_date.day
    year2 = second_date.year
    month2 = second_date.month
    day2 = second_date.day

    data_dolar = get_data(day, month, year, day2, month2, year2, 'dolar')
    data_uf = get_data(day, month, year, day2, month2, year2, 'uf')
    data_tmc = get_data(day, month, year, day2, month2, year2, '', true)

    @dolar = parse_data(data_dolar, 'Dolares')
    @uf = parse_data(data_uf, 'UFs')
    @tmc = parse_tmc(data_tmc).group_by { |d| d[2] }.sort_by { |tmc| tmc[0] }

    @dolar.map{ |dolar|
      @min_dolar = dolar[1].to_f < @min_dolar ? dolar[1].to_f : @min_dolar
      @max_dolar = dolar[1].to_f > @max_dolar ? dolar[1].to_f : @max_dolar
      suma_dolar += dolar[1].to_f
    }
    @prom_dolar = @dolar.length ? (suma_dolar/@dolar.length).round(2) : 0

    @uf.map{ |uf|
      @min_uf = uf[1].to_f < @min_uf ? uf[1].to_f : @min_uf
      @max_uf = uf[1].to_f > @max_uf ? uf[1].to_f : @max_uf
      suma_uf += uf[1].to_f
    }
    @prom_uf = @uf.length ? (suma_uf/@uf.length).round(2) : 0

    @max_tcm_per_type = max_tcm_per_type(@tmc).sort_by { |tmc| tmc[:name] }
  end

  private

  def set_params
    params.require(:range).permit(:first_date, :second_date)
  end

  def validate_date
    first_date = set_params[:first_date].to_date
    second_date = set_params[:second_date].to_date
    if first_date.present? && second_date.present?
      if second_date > first_date
        flash[:notice] = "Busqueda entre los periodos #{set_params[:first_date]} al #{set_params[:second_date]}."
      else
        flash[:alert] = 'Primer periodo no puede ser mayor que el segundo!. Vuelva a Buscar'
        redirect_to root_path
      end
    else
      flash[:alert] = 'Ingresar ambos periodos'
      redirect_to root_path
    end
  end

  def get_data(day, month, year, day2, month2, year2, type, tmc=false)
    api_key = '9c84db4d447c80c74961a72245371245cb7ac15f'
    base_uri = 'http://api.sbif.cl'
    if tmc
      return RestClient.get("#{base_uri}/api-sbifv3/recursos_api/tmc/periodo/#{year}/#{month}/#{year2}/#{month2}?apikey=#{api_key}&formato=json")
    end
    RestClient.get("#{base_uri}/api-sbifv3/recursos_api/#{type}/periodo/#{year}/#{month}/dias_i/#{day}/#{year2}/#{month2}/dias_f/#{day2}?apikey=#{api_key}&formato=json")
  end

  def parse_data(data, type)
    JSON.parse(data.to_str)[type].collect{|i| [i['Fecha'], i['Valor'].gsub('.','').gsub(',','.')]}
  end

  def parse_tmc(data)
    JSON.parse(data.to_str)["TMCs"].collect{|i| [i['Fecha'], i['Valor'].gsub('.','').gsub(',','.'), i['Tipo'] ]}
  end

  def max_tcm_per_type(data)
    max_tcm = []
    data.each{ |k,v| 
      array = {
        name: k,
        max_value: 0,
      }
      v.each { |value|
        if(value[1].to_i > array[:max_value])
          array[:max_value] = value[1].to_i
          array[:date] = value[0]
        end
      }
      max_tcm << array
    }
    max_tcm
  end
end
