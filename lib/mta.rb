# SMTP Test 
class MTA

	def setmtaport()
		if $sec == "tls"
			$sport = 587
		elsif $sec == "ssl"
			$sport = 465
		else
			$sport = 25
		end
	end

	def smtpout(host, msg, from, to)
		begin
			MTA.new.setmtaport()
			puts "Outbound SMTP No Auth Test"
			puts "--------------------------"
			Net::SMTP.start(host, $sport) do |smtp|
				if $sec == "tls"
					smtp.enable_starttls
				end
				smtp.send_message msg, from, to
			end
			puts "   - Message sent. ✅"
			puts ""
			if $sec == "tls"
				Cert.new.check_tls(host, $sport)
			elsif $sec == "ssl"
				Cert.new.check_ssl(host, $sport)
			end
		rescue => e
			puts "   - Outbound SMTP no auth test failed! ❌"
			puts "     Error: #{e} \n"
		end
	end

	def smtpin(host, msg, from, to)
		begin
			puts "Inbound SMTP Test"
			puts "-------------------------"
			Net::SMTP.start(host, 25) do |smtp|
				if $sec == "tls"
					smtp.enable_starttls
				end
				smtp.send_message msg, from, to
			end
			puts "   - Message sent. ✅"
			puts ""
			if $sec == "tls"
				Cert.new.check_tls(host, 25)
			end
		rescue => e
			puts "   - Inbound SMTP test failed! ❌"
			puts "     Error: #{e} \n"
		end
	end

	def smtpauth(host, user, pass, msg, from, to)
		begin
			MTA.new.setmtaport()
			puts "Outbound SMTP Auth Test"
			puts "-----------------------"
			Net::SMTP.start(host, $sport, 'Test Script', user, pass, :login) do |smtp|
				if $sec == "tls"
					smtp.enable_starttls
				elsif $sec == "ssl"
					smtp.enable_ssl
				end
				smtp.send_message msg, from, to
			end
			puts "   - Message sent. ✅"
			puts ""
			if $sec == "tls"
				Cert.new.check_tls(host, $sport)
			elsif $sec == "ssl"
				Cert.new.check_ssl(host, $sport)
			end
		rescue => e
			puts "   - Outbound SMTP auth test failed! ❌"
			puts "     Error: #{e} \n"
		end
	end

end
