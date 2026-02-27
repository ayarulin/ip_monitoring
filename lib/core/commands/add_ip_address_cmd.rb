require_relative '../dao/ips'
require_relative '../entities/ip'
require_relative '../../framework/action'

class Commands::AddIpAddressCmd < Framework::Action
  input do
    required(:ip).filled(:string)
    required(:enabled).filled(:bool)
  end

  def call(input)
    entity = Core::Entities::Ip.new(
      id: nil,
      address: input[:ip],
      created_at: Time.now.utc,
      deleted_at: nil
    )

    @ips.save(entity)

    nil
  rescue Sequel::UniqueConstraintViolation
    raise ArgumentError, 'already exists'
  end
end
