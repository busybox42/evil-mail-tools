class Cert

	def check_ssl(host, port)
		begin
			ctx = OpenSSL::SSL::SSLContext.new
			tcp = TCPSocket.new(host, port)
			ssl = OpenSSL::SSL::SSLSocket.new(tcp, ctx)
			ssl.connect
			cert = ssl.peer_cert
			puts "   - SSL status for #{host} ✅"
			puts "\t State: #{ssl.state}"
			puts "\t Subject: #{cert.subject.to_s}"
			puts "\t Expires: #{cert.not_after}"
			puts
		rescue => e
			puts "   - SSL error for #{host} ❌"
			puts "     SSL Error: #{e}"
		end
	end

	def check_tls(host, port)
		begin
			ctx = OpenSSL::SSL::SSLContext.new
			tcp = TCPSocket.new(host, port)
			tcp.gets
			if port == 110
				tcp.puts 'STLS'
			elsif port == 143
				tcp.puts '. STARTTLS'
			elsif port == 587 || port == 25
				tcp.puts "HELO test script \r"
				tcp.gets
				tcp.puts "STARTTLS \r"
			end
			tcp.gets
			ssl = OpenSSL::SSL::SSLSocket.new(tcp, ctx)

			ssl.connect
			cert = ssl.peer_cert
			puts "   - TLS status for #{host} ✅"
			puts "\t State: #{ssl.state}"
			puts "\t Subject: #{cert.subject.to_s}"
			puts "\t Expires: #{cert.not_after}"
			puts ""
		rescue => e
			puts "   - TLS errpr for #{host} ❌"
			puts "     TLS Error: #{e}"
		end
	end

end
