 # encoding: UTF-8
require 'mechanize'
require 'launchy'


Encoding.default_external = Encoding::UTF_8

class Mechanize::Page

  def open_in_browser
    if body
      file = File.new("/tmp/#{Time.now.to_i}.html", 'w')
      file.write(body.force_encoding('UTF-8'))
      Launchy.open "file://#{file.path}"
      system "sleep 2 && rm #{file.path} &"
    end
  end

end
