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
  puts s if DEBUG
end
 
class ArtifactoryRest < RestClient::Resource; end
    
connection  = ArtifactoryRest.new(url, :user => user, :password => pass)  

def usage
  puts "usage: #{$0} -mode repo|file "
  puts "Mode repo:"
  puts " -oper list -- List repos"
  puts " -oper create -repname Name_of_repo -- Create the repo with name Name_of_respo"
  puts "Mode file:"
  puts " -oper upload -repname Name_of_repo -rfile Name_of_File_on_Repo -lfile Name_of_File_on_PC "
  puts " -oper download -repname Name_of_repo -rfile Name_of_File_on_Repo -lfile Name_of_File_on_PC "
  puts " -oper delete -repname Name_of_repo -rfile Name_of_File_on_Repo  "
end

def search_parameter(param)
  ARGV.each_index { |i| return ARGV[i+1] if ARGV[i] == param }
  puts "Error: there is not the parameter: #{param}"
  usage
  return exit(1)
end

usage if ARGV[0] == "-h" or ARGV[0] == "-help"

mode = search_parameter("-mode")
case mode
  when "repo"
    debug("Works")
    oper = search_parameter("-oper")
    debug(oper)
    case oper
      when "list"
        repos = JSON.parse(connection['/api/repositories'].get)
        repos.each { |re| puts "repo #{re["key"]} type #{re["type"]} URL #{re["url"]}" }
      when "create"
        reponam = search_parameter("-repname")
        debug("Reponame #{reponam}")
        config = {"key"=>"#{reponam}", "description"=>"Test repository for in-house libraries", "notes"=>"", "includesPattern"=>"**/*", "excludesPattern"=>"", "repoLayoutRef"=>"maven-2-default", "enableNuGetSupport"=>false, "enableGemsSupport"=>false, "checksumPolicyType"=>"client-checksums", "handleReleases"=>true, "handleSnapshots"=>false, "maxUniqueSnapshots"=>0, "snapshotVersionBehavior"=>"unique", "suppressPomConsistencyChecks"=>false, "blackedOut"=>false, "propertySets"=>["artifactory"], "archiveBrowsingEnabled"=>false, "calculateYumMetadata"=>false, "yumRootDepth"=>0, "rclass"=>"local"}
        connection["/api/repositories/#{reponam}"].put JSON.generate(config) , :content_type => 'application/json'
    else
      puts " Enter the correct operation: -oper list|create "
      usage
    end
  when "file"
    debug("File")
    oper = search_parameter("-oper")
    reponam = search_parameter("-repname")
    rfile = search_parameter("-rfile")
    case oper
      when "upload"
        lfile = search_parameter("-lfile")
        connection["#{url}/#{reponam}/#{rfile}"].put File.read("#{lfile}"),  :content_type => "application/xml"
      when "delete"
        connection["#{url}/#{reponam}/#{rfile}"].delete
      when "download"
        lfile = search_parameter("-lfile")
        olfile = File.open(lfile, "w")
        olfile << connection["#{url}/#{reponam}/#{rfile}"].get
        olfile.close
      else
        puts " Enter the correct operation: -oper upload|delete|download "
        usage
      end
  else
    puts " Enter the correct mode: -mode repo|file"
    usage
end
