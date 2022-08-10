class Web

	def check_https(host)
		begin
			puts "Checking HTTPS"
			puts "--------------"
			Cert.new.check_ssl(host, 443)

		rescue => e
			puts "HTTPS cert check failed!"
			puts "Error: #{e}"
		end
	end

	def zimbra_preauth(host, user, key)
		begin
			ts = DateTime.now.strftime('%Q')
			data = "#{user}|name|0|#{ts.to_i}"
			mac = OpenSSL::HMAC.hexdigest("SHA1", key, data)

			uri = URI.parse("https://#{host}/service/preauth?account=#{user}&expires=0&timestamp=#{ts.to_i}&preauth=#{mac}")
			request = Net::HTTP::Get.new(uri)

			unless $noverify.nil?
				req_options = {
					use_ssl: uri.scheme == "https",
					verify_mode: OpenSSL::SSL::VERIFY_NONE,
				}
			else 
				req_options = {
					use_ssl: uri.scheme == "https",
				}
			end

			response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
				http.request(request)
			end

			puts "   - Sending preauth"
			puts "\t URL: https://#{host}/service/preauth?account=#{user}&expires=0&timestamp=#{ts.to_i}&preauth=#{mac}"
			if response.code == "302"
				puts "\t Success: Preauth login redirect response code: #{response.code} ✅"
			else
				puts "\t Fail: Preauth login redirect response code: #{response.code} ❌"
			end
			puts ""
		rescue => e
			puts "   - Zimbra preauth error ❌"
			puts "     Error: #{e}"
			puts ""
		end
	end

end
