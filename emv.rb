#!/usr/bin/env ruby

require 'rubygems'
require 'optparse'
require 'parseconfig'
require 'net/smtp'
require 'net/pop'
require 'net/imap'
require 'resolv'
require 'net/http'
require 'uri'
require 'date'

Dir["#{Dir.pwd}/lib/*.rb"].each {|file| require file }

# Options
#
options = {}
opt_parser = OptionParser.new do |opts|
	opts.banner = "💎 Usage: emv.rb [options]"
	opts.on("-f", "--from [ADDRESS]", "SMTP from address. Defaults to --auth if fully qualified.", String) { |val| $from = val }
	opts.on("-t", "--to [ADDRESS]", "SMTP to address. Defaults to --auth if fully qualified.", String) { |val| $to = val }
	opts.on("-H", "--host [ADDRESS]", "Specify single hostname for outbound SMTP, POP3, IMAP and webmail.", String) { |val| $host = val }
	opts.on("-i", "--imap [ADDRESS]", "IMAP specific hostname.", String) { |val| $imap = val }
	opts.on("-p", "--pop [ADDRESS]", "POP3 specific hostname.", String) { |val| $pop = val }
	opts.on("-s", "--smtp [ADDRESS]", "SMTP specific hostname.", String) { |val| $smtp = val }
	opts.on("-w", "--web [ADDRESS]", "Webmail specific hostname.", String) { |val| $web = val }
	opts.on("-k", "--key [KEY]", "Zimbra preauth key.", String) { |val| $key = val }
	opts.on("-m", "--mx [ADDRESS]", "MX hostname (Will try and resolve based on the --to domain if not specificed.)", String) { |val| $mx = val }
	opts.on("-a", "--auth [USER NAME]", "Username to authenticate as.", String) { |val| $auth = val }
	opts.on("-P", "--pass [PASSWORD]", "Password to authenticate with.", String) { |val| $pass = val }
	opts.on("-c", "--config [FILE]", "Configuration file with variables for tests.", String) { |val| $config = val }
	opts.on("-C", "--check [web|pop|imap|smtp|mx|all]", "Specify type of mail test. Default: all", String) { |val| $check = val }
	opts.on("-S", "--security [ssl|tls|none]", "Perform TLS or SSL login. Default: none", String) { |val| $sec = val }
	opts.on("-n", "--noverify", "Accept invalid SSL certificates.") do
		$noverify = true
	end
	opts.on("-l", "--clean", "Delete recent message from inbox.") do
		$clean = true
	end
	opts.on("-h", "--help", "Usage options.") do
		puts opts
		exit
	end
	begin opts.parse! ARGV
	rescue => e
		puts "Error: #{e} 😡"
		puts opts
		exit
	end
	opts.parse!

	# Make sure some options are set depending on tests.
	#
	# 
	# Run all checks if not specificed
	begin

		# Load config
		unless $config.nil?
			config = ParseConfig.new($config)
			if $from.nil?
				$from = config['from']
			end
			if $to.nil?
				$to = config['to']
			end
			if $host.nil?
				$host = config['host']
			end
			if $imap.nil?
				$imap = config['imap']
			end
			if $pop.nil?
				$pop = config['pop']
			end
			if $smtp.nil?
				$smtp = config['smtp']
			end
			if $web.nil?
				$web = config['web']
			end
			if $mx.nil?
				$mx = config['mx']
			end
			if $key.nil?
				$key = config['key']
			end
			if $auth.nil?
				$auth = config['auth']
			end
			if $pass.nil?
				$pass = config['pass']
			end
			if $sec.nil?
				$sec = config['security']
			end
			if $check.nil?
				$check = config['check']
			end
		end

		# Run all checks if not set
		if $check.nil?
			$check = "all"
		end

		# If mx is not specified look it up
		if $check == "all" || $check == "mx"
			unless $auth.nil?
				if $auth.include? "@"
					if $from.nil?
						$from = $auth
					end
					if $to.nil?
						$to = $auth
					end
				end
			else
				puts "Invalid options selected. ❌"
				puts "Hint: specify --to or fully qualify --auth."
				puts opts
				exit
			end
			if $mx.nil?
				domain = $to.split("@")[1]
				Resolv::DNS.open do |dns|
					ress = dns.getresources domain, Resolv::DNS::Resource::IN::MX
					$mxa = ress.map { |r| r.exchange.to_s }
				end
				$mx = $mxa[0]
			end
		end

		# Make sure we set auth info when we need to login
		if $check == "all" || $check == "imap" ||  $check == "pop" || $check == "smtp"
			if $auth.nil? || $pass.nil?
				puts "Invalid options selected. ❌"
				puts "Missing authentication info."
				puts opts
				exit
			end
		end
		if $check == "web"
			if $auth.nil? || $key.nil?
				puts "Invalid options selected. ❌"
				puts "Missing authentication info."
				puts opts
				exit
			end
		end

		# If --host is not set make use user is setting --imap, --pop3, --smtp and --web where required.
		if $host.nil?
			if $check == "all"
				if $imap.nil? || $pop.nil? || $smtp.nil? || $web.nil?
					puts "Invalid options selected. ❌"
					puts "Check hostname options."
					puts opts
					exit
				end
			elsif $check == "imap"
				if $imap.nil?
					puts "Invalid options selected. ❌"
					puts "Check hostname options."
					puts opts
					exit
				end
			elsif $check == "pop"
				if $pop.nil?
					puts "Invalid options selected. ❌"
					puts "Check hostname options."
					puts opts
					exit
				end
			elsif $check == "smtp"
				if $smtp.nil?
					puts "Invalid options selected. ❌"
					puts "Check hostname options."
					puts opts
					exit
				end
			elsif $check == "web"
				if $web.nil?
					puts "Invalid options selected. ❌"
					puts "Check hostname options."
					puts opts
					exit
				end
			end
		else
			if $imap.nil?
				$imap = $host
			end
			if $pop.nil?
				$pop = $host
			end
			if $smtp.nil?
				$smtp = $host
			end
			if $web.nil?
				$web = $host
			end
		end

	rescue => e

		puts "Run time error. 😡"
		puts "Error: #{e.message}"
		exit

	end
end

# Message Contents
#
$msgstrout = <<END_OF_MESSAGE
From: #{$from}
To: #{$to}
Subject: Outbound SMTP Test Message

This is a test message.

END_OF_MESSAGE

$msgstrin = <<END_OF_MESSAGE
From: #{$from}
To: #{$to}
Subject: Inbound SMTP Test Message

This is a test message.

END_OF_MESSAGE

# Start checks
#
begin

	unless $check == "all"
		if $check == "pop"
			Proxy.new.check_pop($pop, $auth, $pass)
		elsif $check == "imap"
			Proxy.new.check_imap($imap, $auth, $pass)
		elsif $check == "smtp"
			if $auth.nil?
				MTA.new.smtpout($smtp, $msgstrout, $from, $to)
			else
				MTA.new.smtpauth($smtp, $auth, $pass, $msgstrout, $from, $to)
			end
		elsif $check == "mx"
			MTA.new.smtpin($mx, $msgstrin, $from, $to)
		elsif $check == "web"
			Web.new.check_https($web)
			Web.new.zimbra_preauth($web, $auth, $key)
		end
	else
		Web.new.check_https($web)
		Web.new.zimbra_preauth($web, $auth, $key)
		MTA.new.smtpin($mx, $msgstrin, $from, $to)
		sleep 2
		if $auth.nil?
			MTA.new.smtpout($smtp, $msgstrout, $from, $to)
		else
			MTA.new.smtpauth($smtp, $auth, $pass, $msgstrout, $from, $to)
		end
		sleep 2
		Proxy.new.check_pop($pop, $auth, $pass)
		Proxy.new.check_imap($imap, $auth, $pass)
	end

	if $clean == true
		Proxy.new.clean_imap($imap, $auth, $pass)
	end
	puts "Complete. 👌"

rescue => e
	puts "Runtime Error 😡"
	puts "Error: #{e.message}"

end
