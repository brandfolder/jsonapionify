require 'pry' rescue nil
require 'core_ext/boolean'
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash/keys"
require 'active_support/cache'
require 'jsonapionify/autoload'

module JSONAPIonify
  autoload :VERSION, 'jsonapi-objects/version'
  extend JSONAPIonify::Autoload
  autoload_all 'jsonapionify'

  def self.path
    __dir__
  end

  def self.parse(hash)
    hash = JSON.parse(hash) if hash.is_a? String
    Structure::Objects::TopLevel.from_hash(hash)
  end

  def self.new_object(*args)
    Structure::Objects::TopLevel.new(*args)
  end

  def self.cache(store, *args)
    self.cache_store = ActiveSupport::Cache.lookup_store(store, *args)
  end

  def self.digest
    @digest ||= Digest::SHA2.hexdigest(
      Dir.glob(File.join __dir__, '**/*.rb').map { |f| File.read f }.join
    )
  end

  def self.cache_store=(store)
    @cache_store = store
  end

  def self.cache_store
    @cache_store ||= ActiveSupport::Cache.lookup_store :null_store
  end
end
