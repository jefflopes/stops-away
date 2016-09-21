require 'sinatra'

def simple_format(text)
      text.gsub!(/ +/, " ")
      text.gsub!(/\r\n?/, "\n")
      text.gsub!(/\n/, "<br />\n")
      text
end

get '/' do
  simple_format(`ruby stops_away.rb`)
end
