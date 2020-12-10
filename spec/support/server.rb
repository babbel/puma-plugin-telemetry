# frozen_string_literal: true

class Server
  attr_reader :lines

  def initialize(config = "config")
    @config = config
    @lines = []
  end

  def start
    @server = IO.popen("PUMA_DEBUG=1 bundle exec puma -C spec/fixtures/#{@config}.rb -b unix://#{bind_path}", "r")
    true while next_line !~ /Ctrl-C/
    @pid = @server.pid
  end

  def stop
    stop_server
    cleanup_bindfile

    return if @server.nil? || @server&.closed?

    @server.close
    @server = nil
  end

  def next_line
    @lines << @server.gets
    puts @lines.last if ENV.key?("DEBUG_TEST")
    @lines.last
  end

  private

  def bind_path
    @bind_path ||= Tempfile.create(["", ".sock"], &:path)
  end

  def cleanup_bindfile
    File.unlink(@bind_path)
  rescue Errno::ENOENT # rubocop:disable Lint/SuppressedException
  end

  def stop_server
    begin
      Process.kill :TERM, @pid
    rescue Errno::ESRCH # rubocop:disable Lint/SuppressedException
    end

    begin
      Process.wait2 @pid
    rescue Errno::ECHILD # rubocop:disable Lint/SuppressedException
    end
  end
end
