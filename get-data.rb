#!/usr/local/bin/ruby
# encoding: utf-8

require 'json'
require 'nokogiri'
require 'open-uri'
require 'time'

html = Nokogiri::HTML(open('http://dotabuff.com/heroes'))

roles = html.css('#role_javascript option[value!="All Roles"]').map {|option|
	role = {
		id: option['value'].strip.downcase.sub(' ', '-'),
		name: option.content.strip
	}
	$stderr.puts role.inspect
	if (role[:name].empty?)
		'role name empty for ' + hero[:id]
		exit 1
	end
	role
}

heroes = html.css('.hero-grid > a').map {|a|
	hero = {
		id: a['href'].match(/\/heroes\/([^\/]+)\/?/)[1],
		name: a.css('.name').first.content.strip,
		roles: a['class'].downcase.split(' '),
	}
	if (!hero[:id] or hero[:id].strip.empty?)
		$stderr.puts 'hero has no id'
		exit 1
	end
	if (!hero[:name] or hero[:name].strip.empty?)
		$stderr.puts 'name empty for ' + hero[:id]
		exit 1
	end
	$stderr.puts hero.inspect

	hero_html = Nokogiri::HTML(open('http://dotabuff.com/heroes/' + hero[:id] + '/matchups?date=week'))

	#win_rate = hero_html.css('.won').first.content.delete('.').to_i
	#hero[:win_rate] = win_rate

	matchups = hero_html.css('#page-content tbody tr').map {|tr|
		matchup = {
			hero_id: tr.css('.hero-link').first['href'].match(/\/heroes\/([^\/]+)\/?/)[1],
			advantage: tr.css('td')[2].content.delete('.').to_i,
			win_rate: tr.css('td')[3].content.delete('.').to_i,
			popularity: tr.css('td')[4].content.delete(',').to_i
		}
		$stderr.puts matchup.inspect
		matchup
	}
	if (matchups.empty?)
		$stderr.puts 'matchups empty for ' + hero[:id]
		exit 1
	end
	hero[:win_rate] = matchups.reduce(0) {|t, matchup| t + matchup[:win_rate] } / matchups.length
	hero[:matchups] = matchups
	hero
}

orig_length = heroes.length
if (heroes.uniq {|hero| hero[:id] }.length != orig_length)
	$stderr.puts 'duplicate heroes'
	exit 1
end

data = {
	retrieval_time: Time.now.utc,
	roles: roles,
	heroes: heroes
}
puts JSON.pretty_generate(data, indent: "\t")
