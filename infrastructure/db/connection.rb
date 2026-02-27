require 'sequel'
require 'logger'

module Infrastructure::Db::Connection
  def self.build(url: ENV.fetch('DATABASE_URL'))
    db = Sequel.connect(url)

    db.timezone = :utc
    db.typecast_timezone = :utc

    if ENV['DB_LOG'] == 'true'
      db.loggers << Logger.new($stdout)
    end

    db
  end
end

