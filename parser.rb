require 'json'
require 'uri'

def prompt
  print '> '
  gets
end

puts 'Кого парсим? (юзернейм, без собаки)'
who = prompt.strip

data = `./tg/bin/telegram-cli --json -f -D --disable-readline -e 'resolve_username #{who}'`

data.sub!("halt\nAll done. Exit", '').strip!

id = JSON.parse(data)['id']

puts "ID: #{id}"

puts 'Парсим посты...'

total = []

offset = 0

loop do
  posts = []

  data = `./tg/bin/telegram-cli --json -f -D --disable-readline -e 'history #{id} 100 #{offset}'`

  data.sub!("halt\nAll done. Exit", '').strip!

  posts = JSON.parse(data)

  puts "Спарсил #{offset + posts.size}"

  offset += 100

  total.push(*posts)

  break if posts.size.zero?

  sleep 1
end

sentences = []

total.each do |post|
  next if post.key? 'fwd_from'
  next unless post.key? 'text'

  text = post['text']
  text.gsub!(URI.regexp, '')
  # Удаляет списки вида 1. 2. 3.
  text.gsub!(/^\d\./, '')
  text.delete!("\n")
  text.gsub!('гг.', '')
  text.gsub!('г.', 'г')
  text.gsub!('т.к.', 'так как')

  sntcs = text.split(/(?<=[.!])/)
  sntcs.map!(&:strip)
  sntcs.map! { |s| s.squeeze(' ') }
  sntcs.reject! { |s| s.size < 5 }

  sentences.push(*sntcs)
end

open("parsed/#{who}.txt", 'w') do |f|
  sentences.each do |s|
    f.puts s
  end
end
