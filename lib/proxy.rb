class Proxy

	def setproxyports()
		if $sec == "ssl"
			$pport = 995
			$iport = 993
		else
			$pport = 110
			$iport = 143
		end
	end

	# POP3 test
	def check_pop(host, user, pass)
		begin
			setproxyports()
			puts "Checking POP3"
			puts "-------------"
			Net::POP3.start(host, $pport, user, pass) do |pop|
				if $sec.nil?
					pop.disable_ssl
				end
				if pop.mails.empty?
					puts 'No mail.'
				else
					i = 0
					pop.each_mail do |m|
						i += 1
					end
					puts "   - #{pop.mails.size} message in inbox. ✅"
				end
			end
			puts ""
			if $sec == "tls"
				Cert.new.check_tls(host, $pport)
			elsif $sec == "ssl"
				Cert.new.check_ssl(host, $pport)
			end
		rescue => e
			puts "   - POP3 check failed! ❌"
			puts "     Error: #{e}"
		end
	end

	# IMAP Test
	def check_imap(host, user, pass)
		begin
			setproxyports()
			if $sec == "ssl"
				opt = "ssl: true"
			end
			puts "Checking IMAP"
			puts "-------------"
			imap = Net::IMAP.new(host, $iport, opt)
			if $sec == "tls"
				imap.starttls
			end
			imap.authenticate('LOGIN', user, pass)
			imap.examine('INBOX')
			imap.search(["RECENT"]).each do |message_id|
				envelope = imap.fetch(message_id, "ENVELOPE")[0].attr["ENVELOPE"]
				puts "   #{envelope.from[0].mailbox}@#{envelope.from[0].host}: \t#{envelope.subject}"
			end
			imap.logout
			puts "   - Success. ✅"
			puts ""
			if $sec == "tls"
				Cert.new.check_tls(host, $iport)
			elsif $sec == "ssl"
				Cert.new.check_ssl(host, $iport)
			end
		rescue => e
			puts "   - IMAP check failed! ❌"
			puts "     Error: #{e}"
		end
	end

	# IMAP Clean
	def clean_imap(host, user, pass)
		begin
			setproxyports()
			if $sec == "ssl"
				opt = "ssl: true"
			end
			puts "Purging recent messages"
			puts "-----------------------"
			imap = Net::IMAP.new(host, $iport, opt)
			if $sec == "tls"
				imap.starttls
			end
			imap.authenticate('LOGIN', user, pass)
			imap.select('INBOX')
			recent = imap.search(["RECENT"])
			puts "   - Deleting #{recent.count} recent messages. ✅"
			recent.each do |message_id|
				imap.copy(message_id, "TRASH")
				imap.store(message_id, "+FLAGS", [:Deleted])
			end
			imap.expunge
			imap.logout
			puts ""
		rescue => e
			puts "   - IMAP clean failed! ❌"
			puts "     Error: #{e}"
		end
	end

end
