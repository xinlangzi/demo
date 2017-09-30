require 'net/sftp'

module Edi
  class SftpServer
    def self.connect(provider, direction)
      server = SftpServer.new(provider, direction)
      yield server
      server.close
    end

    def initialize(provider, direction)
      @provider = provider
      @direction = direction.to_s
      options = {
        timeout: 10,
      }
      
      pw = @provider.send((@direction + '_password').to_sym)
      options.merge!({password: pw}) if pw
      kd = @provider.send((@direction + '_key_data').to_sym)
      options.merge!({key_data: [kd]}) if kd.present?
      @connection = Net::SFTP.start(@provider.send((@direction + '_server').to_sym), @provider.send((@direction + '_login')), options)
    end

    def send_file(f, document_num)
      name = "#{@provider.outbound_directory}/#{document_num}_#{Time.now.to_i}"
      @connection.upload!(f.path, name)
      name
    end

    def for_each
      begin
        @connection.dir.foreach(@provider.inbound_directory) do |entry|
          next if entry.name =~ /^\./
          file = "#{@provider.inbound_directory}/#{entry.name}"
          Rails.logger.info("#{Time.now} EDI: About to retrieve #{file}")
          # yield @connection.download!(file).gsub(/\n/, "~")
          yield @connection.download!(file).encode!("UTF-8", invalid: :replace, undef: :replace).gsub(/\n/, "~")
          @connection.remove!(file)
        end
      rescue Net::SFTP::StatusException => ex
        raise ex unless ex.message =~ /no such file/
        Rails.logger.info("#{Time.now} EDI: found no files")
      end
    end

    def close
      @connection.close_channel
    end
  end
end