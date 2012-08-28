require 'rubygems'
require 'aws-sdk'
require 'yaml'

class S3Up
  def initialize(args)
    @aws = AWS.config(parse_config_file)
    @bucket = args.shift
    @files = args
    @printer = Proc.new do |list|
      <<-eos
      urls = #{ list.collect { |(name, link)| "{ '#{name}' : '#{link}'}" }.join(',') }
      eos
    end

    puts @printer.call upload(@files)
  end

  def upload(files)
    files.collect do |file|
      basename = File.basename(file)
      object = bucket.objects[basename]
      puts "Uploading #{file}"
      object.write(:file => file, :acl => :public_read)
      [basename, object.public_url.to_s]
    end
  end

  private

  def parse_config_file
    config_file = File.join(File.dirname(__FILE__), "config.yml")
    YAML.load(File.read(config_file))
  end

  def bucket
    @s3_bucket ||= AWS::S3.new.buckets.create(@bucket)
  end
end

S3Up.new(ARGV)
