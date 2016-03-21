require 'open-uri'

OpenURI::Buffer.send :remove_const, 'StringMax' if OpenURI::Buffer.const_defined?('StringMax')
OpenURI::Buffer.const_set 'StringMax', 0

module Learning

	class Scraper
		attr_accessor :count, :category, :type

		def initialize(count: 100, category:'long sleeved shirt', type:'train', offset: 0)
			@offset = offset
			@num_loaded = 0
			@category = category
			@type = type
			@count = count
		end

		def load_images
			while @num_loaded < @count
				search_string = @category.gsub(' ', '+')
				session = Capybara::Session.new(:poltergeist)
				session.visit(build_url)
				images = session.all('img')
				@offset += images.length

				images.each do |image|
					load_item(image)
				end
			end
		end

		def already_loaded?(phash)
			return Item.exists?(phash: phash)
		end

		def load_item(image)
			url = image['src']
			begin
				phash = Phashion::Image.new(open(url).path).fingerprint
			rescue 
				continue
			end
			if !already_loaded?(phash)
				item = Item.new(category: @category, phash: phash, item_type: @type, url: url)
				item.save
				@num_loaded += 1
			end
		end

		private
			def build_url
				search_string = @category.gsub(' ', '+')
				return 'https://www.google.com/search?tbm=isch&q=' + search_string + '&start=' + @offset.to_s
			end
	end

	class Classifier
		attr_accessor :count, :category, :type

		def initialize(k: 3)
			@k = k
		end

		def run_test_on_url(url)
			phash = Phashion::Image.new(open(url).path).fingerprint
			k_closest = find_closest_items(phash)
			k_closest_categories = k_closest.map{|x| x['category']}
			puts k_closest
			most_common_category = k_closest_categories.group_by(&:itself).values.max_by(&:size).first
			return most_common_category
		end

		def run_test(category)
			unrun_tests = Item.where(category: category, item_type: 'test')
						.where('result IS NULL')

			unrun_tests.each do |item|
				closest_item = find_closest_item(item.phash)
				category = closest_item.category
				if closest_item.phash == item.phash
					item.update(:result => 'identical')
				else
					item.update(:result => category)
				end
			end
		end

		private 
			def find_closest_items(phash)
				all_items = Item.where(item_type: 'train')
				all_results = []

				all_items.each do |compare_item|
					comparison_result = Hash.new
				    hamming_distance = (compare_item.phash.to_i ^ phash.to_i).to_s(2).count("1")
				    comparison_result['category'] = compare_item.category
				    comparison_result['distance'] = hamming_distance
				    all_results << comparison_result
				end
				
				k_closest = all_results.sort_by { |k| k["distance"] }.first(@k)
			end
	end
end








