#!/usr/bin/env ruby
#This script was written by Stas Makar <stamak@rambler.ru>
#If you have any questions, feel free to ask. 
require 'rest-client'
require 'json'
#Credentials and url
user = 'user'
pass = 'pass'
url = 'https://test.artifactoryonline.com/test'

DEBUG = false
def debug(s)
	if DEBUG
		puts s
	end
end

def Usage()
	puts "Usage: #{$0} -mode repo|file "
	puts "Mode repo:"
	puts " -oper list -- List repos"
	puts " -oper create -repname Name_of_repo -- Create the repo with name Name_of_respo"
	puts "Mode file:"
	puts " -oper upload -repname Name_of_repo -rfile Name_of_File_on_Repo -lfile Name_of_File_on_PC "
	puts " -oper download -repname Name_of_repo -rfile Name_of_File_on_Repo -lfile Name_of_File_on_PC "
	puts " -oper delete -repname Name_of_repo -rfile Name_of_File_on_Repo  "
end

def searchparam(param)
	ARGV.each_index do |i|
		if ARGV[i] == param
			return ARGV[i+1]
		end
	end
	puts "Error: there is not the parameter: #{param} \n"
	Usage()
	exit(1)
end

if ARGV[0] == "-h" or ARGV[0] == "-help"
	        print Usage()
end

mode = searchparam("-mode")
if mode == "repo"
	debug("Works")
	oper = searchparam("-oper")
	debug(oper)
	if oper == "list"
		conn = RestClient::Resource.new "#{url}/api/repositories"
		repos = JSON.parse(conn.get)
		repos.each { |re| print "repo #{re["key"]} type #{re["type"]} URL #{re["url"]}  \n" }
	elsif oper == "create"
		reponam = searchparam("-repname")
		debug("Reponame #{reponam}")
		config = {"key"=>"#{reponam}", "description"=>"Test repository for in-house libraries", "notes"=>"", "includesPattern"=>"**/*", "excludesPattern"=>"", "repoLayoutRef"=>"maven-2-default", "enableNuGetSupport"=>false, "enableGemsSupport"=>false, "checksumPolicyType"=>"client-checksums", "handleReleases"=>true, "handleSnapshots"=>false, "maxUniqueSnapshots"=>0, "snapshotVersionBehavior"=>"unique", "suppressPomConsistencyChecks"=>false, "blackedOut"=>false, "propertySets"=>["artifactory"], "archiveBrowsingEnabled"=>false, "calculateYumMetadata"=>false, "yumRootDepth"=>0, "rclass"=>"local"}
		conn = RestClient::Resource.new "#{url}/api/repositories/#{reponam}", "#{user}", "#{pass}"
		conn.put JSON.generate(config) , :content_type => 'application/json'
	else
		puts " Enter the correct operation: -oper list|create "
		Usafe()
	end
elsif mode == "file"
	debug("File")
	oper = searchparam("-oper")
	 if oper == "upload"
		reponam = searchparam("-repname")
		rfile = searchparam("-rfile")
		lfile = searchparam("-lfile")
		conn = RestClient::Resource.new "#{url}/#{reponam}/#{rfile}", "#{user}", "#{pass}"
		conn.put File.read("#{lfile}"),  :content_type => "application/xml"
	elsif oper == "delete"
		reponam = searchparam("-repname")
		rfile = searchparam("-rfile")
		conn = RestClient::Resource.new "#{url}/#{reponam}/#{rfile}", "#{user}", "#{pass}"
		conn.delete
	elsif oper == "download"
		reponam = searchparam("-repname")
		rfile = searchparam("-rfile")
		lfile = searchparam("-lfile")
		olfile = File.open(lfile, "w")
		conn = RestClient::Resource.new "#{url}/#{reponam}/#{rfile}", "#{user}", "#{pass}"
		olfile << conn.get
		olfile.close
	else
		puts " Enter the correct operation: -oper upload|delete|download "
		Usage()
	end
else
	puts " Enter the correct mode: -mode repo|file"
	Usage()
end

