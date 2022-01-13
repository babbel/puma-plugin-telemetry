# frozen_string_literal: true

class Server
  attr_reader :lines

  def initialize(config = "config")
    @config = config
    @lines = []
  end

  def start
    @server = IO.popen("BIND_PATH=#{bind_path} bundle exec puma -C spec/fixtures/#{@config}.rb --log-requests --debug", "r")
    @server_pid = @server.pid

    true while next_line !~ /PID:\ /
    @puma_pid = @lines.last.split(": ").last.to_i

    true while next_line !~ /Ctrl-C/
  end

  def stop
    stop_server(@puma_pid)
    stop_server(@server_pid)

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

  def bind_path
    @bind_path ||= Tempfile.create(["", ".sock"], &:path)
  end

  private

  def cleanup_bindfile
    File.unlink(@bind_path)
  rescue Errno::ENOENT # rubocop:disable Lint/SuppressedException
  end

  def stop_server(pid)
    return if pid.nil?

    begin
      Process.kill :KILL, pid
    rescue Errno::ESRCH # rubocop:disable Lint/SuppressedException
    end

    begin
      Process.wait2 pid
    rescue Errno::ECHILD # rubocop:disable Lint/SuppressedException
    end
  end
end
