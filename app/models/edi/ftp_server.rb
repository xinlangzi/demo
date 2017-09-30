require 'net/ftp'

module Edi
  class FtpServer
    def self.connect(provider, direction)
      server = FtpServer.new(provider, direction)
      yield server
      server.close
    end

    def initialize(provider, direction)
      @direction = direction.to_s
      @provider = provider
      @connection = Net::FTP.new(@provider.send((@direction + "_server").to_sym))
      @connection.login(@provider.send((@direction + "_login").to_sym), @provider.send((@direction + "_password").to_sym))
      @connection.passive = @provider.send((@direction + "_use_passive").to_sym)
    end

    def close
      @connection.close
    end

    def send_file(f, document_num)
      @connection.chdir(@provider.outbound_directory)
      name = "#{document_num}_#{Time.now.to_i}"
      @connection.put(f.path, name)
      name
    end

    def for_each
      @connection.chdir(@provider.inbound_directory)
      begin
        @connection.nlst.each do |file|
          Rails.logger.info("#{Time.now} EDI: About to retrieve #{file}")
          yield @connection.get(file, nil).encode!("UTF-8", invalid: :replace, undef: :replace).gsub(/\n/, "~")
          @connection.delete(file)
        end
      rescue Net::FTPPermError => ex
        raise ex unless ex.message =~ /550/
        Rails.logger.info("#{Time.now} EDI: found no files")
      rescue Net::FTPTempError => ex
        raise ex unless ex.message =~ /450/
        Rails.logger.info("#{Time.now} EDI: found no files")
      end
    end
  end
end