# manages the federation of datasources
# distributes queries to right datasources and merges their results
require 'federation/connection_pool'
class FederationManager

  # add triple s,p,o to the currently selected write-adapter
	def FederationManager.add(s,p,o)
	  # TODO: allow addition of full graphs	
	  ConnectionPool.write_adapter.add(s,p,o)
	end
	
	# executes read-only queries
	# by distributing query over complete read-pool
	# and aggregating the results
	def FederationManager.query(q, options={:flatten => true})
		# ask each adapter for query results
		# and yield them consequtively
		if block_given? 
			ConnectionPool.read_adapters.each do |source| 
				source.query(q) do |*clauses|
					yield(*clauses)
				end
			end
		else
			# build Array of results from all sources
			# TODO: write test for sebastian's select problem 
			# (without distinct, should get duplicates, they 
			# were filtered out when doing results.union)
			results = []
			ConnectionPool.read_adapters.each { |source| results << source.query(q) }
			
			# filter the empty results
			results.reject {|ary| ary.empty? }

			# remove duplicate results from multiple 
			# adapters if asked for distinct query
			# (adapters return only distinct results, 
			# but they cannot check duplicates against each other)
			results.uniq! if q.distinct?
						
			# flatten results array if only one select clause
			# to prevent unnecessarily nested array [[eyal],[renaud],...]
			results.flatten! if q.select_clauses.size == 1
			
			# and remove array (return single value) unless asked not to 
			if options[:flatten]
  			case results.size
  			when 0
  			 nil
  			when 1
  			 results.first
  			else
  			 results			
  			end
  		else
  		  results 
  		end
  		
		end
	end
end