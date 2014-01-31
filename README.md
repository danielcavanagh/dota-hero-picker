dota-hero-picker
================

calculates the best dota 2 hero to use in given team compositions based on win rates and matchups scraped from dotabuff.com

## requirements

```
gem install nokogiri
```

## usage

```
# scrape the data first
./get-data.rb > data

./dota-hero-picker.rb [-d hero]* [-r hero]*
./dota-hero-picker.rb -s

	-d add a hero to dire
	-r add a hero to radiant
	-s generate random compositions for both teams and give the win rate
```
