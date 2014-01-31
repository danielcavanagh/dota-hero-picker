#!/usr/bin/ruby
# encoding: utf-8

require 'json'
require 'time'

class Integer
	def to_percent
		(self / 100).to_s + '.' + (self % 100).to_s + '%'
	end
end

def determine_best_hero(possible_heroes, team, opponents)
	partial_team_win_rate = get_partial_team_win_rate(hero, opponents)
	possible_heroes.map {|hero|
		{
			:hero => hero,
			:win_rate => (partial_team_win_rate + get_hero_win_rate(hero, opponents)) / 5
		}
	}.sort {|a, b| a[:win_rate] <=> b[:win_rate] }
end

def get_partial_team_win_rate(team, opponents)
	team.reduce(0) {|t, hero| t + get_hero_win_rate(hero, opponents) }
end

def get_team_win_rate(team, opponents)
	get_partial_team_win_rate(team, opponents) / 5
end

def get_hero_win_rate(hero, opponents)
	opponents.empty? ?
		hero[:win_rate] :
		opponents.reduce(0) {|t, opponent| t + get_matchup_win_rate(hero, opponent) } / opponents.length
end

def get_matchup_win_rate(hero, opponent)
	hero[:matchups].each {|matchup|
		return matchup[:win_rate] if matchup[:hero_id] == opponent[:id]
	}
	throw 'can\'t find hero matchup for ' + hero[:id] + ' and ' + opponent[:id]
end

def process_hero_string(string)
	string.downcase.gsub(/\s+/, ' ').split(/ ?, ?/).map {|name|
		$heroes.find {|hero| hero[:id] == name || hero[:name].downcase == name }
	}.compact.uniq
end

data = JSON.parse(open('data').read, symbolize_names: true)
$retrieval_time = Time.parse(data[:retrieval_time])
$roles = data[:roles]
$heroes = data[:heroes]
$available_heroes = $heroes.dup
$dire = []
$radiant = []
$simulate = false

puts 'data retrieval time: ' + $retrieval_time.dup.localtime.to_s

while ARGV.first and ARGV.first[0] == '-'
	ARGV.shift[1..-1].chars.each {|char|
		case char
		when 'd'
			$dire += process_hero_string(ARGV.shift)
			$dire.uniq!
			puts 'too many dire heroes' || usage if $dire.length > 5
		when 'r'
			$radiant += process_hero_string(ARGV.shift)
			$radiant.uniq!
			puts 'too many radiant heroes' || usage if $radiant.length > 5
		when 's'
			$simulate = true
		else usage
		end
	}
end

if $simulate
	$heroes.shuffle!
	$dire = (0..4).to_a.map {|i| $heroes[i] }
	$radiant = (5..9).to_a.map {|i| $heroes[i] }
end

$available_heroes -= $dire
$available_heroes -= $radiant

if not $simulate
	team, opponents = $radiant.length < $dire.length ? [$radiant, $dire] : [$dire, $radiant]
	while $radiant.length < 5 or $dire.length < 5
		partial_win_rate = get_partial_team_win_rate(team, opponents)
		best = $available_heroes.reduce({ win_rate: 0 }) {|best, hero|
			win_rate = get_hero_win_rate(hero, opponents)
			win_rate > best[:win_rate] ? {
				hero: hero,
				win_rate: win_rate
			} : best
		}
		team << best[:hero]
		$available_heroes.delete(best[:hero])
		puts (team == $radiant ? 'radiant' : 'dire') + ' gains: ' + best[:hero][:name].downcase + ', ' + best[:win_rate].to_percent
		team, opponents = opponents, team if team.length >= opponents.length || team.length == 5
	end
end

puts 'radiant heroes: ' + $radiant.map {|hero| hero[:name].downcase }.join(', ')
puts 'dire heroes: ' + $dire.map {|hero| hero[:name].downcase }.join(', ')

adv = get_team_win_rate($radiant, $dire)
puts 'radiant win rate: ' + adv.to_percent
