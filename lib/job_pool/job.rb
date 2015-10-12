# Fires off a child process, feeds it, and keeps track of the results.

require 'open3'
require 'tempfile'
require 'stringio'


class JobPool; end


# A job keeps track of the child process that gets forked.
# job is the Ruby data structure, process is the Unix process.
class JobPool::Job
  attr_reader :start_time, :stop_time     # start and finish times of this job
  attr_reader :stdin, :stdout, :stderr    # fds for child's stdin/stdout/stderr

  # **internal**: Use [JobPool#launch], don't call this method directly.
  #
  # Starts a process.
  #
  # ## Parameters
  #
  # * pool [JobPool]: The pool that will contain this job.
  # * command [String, Array]: The command to run.  Can be specified either
  #                  as a string or an array of arguments for Process.spawn.
  #
  # ## Options
  #
  # * stdin [IO, String]: The child's input.  If an IO object isn't supplied,
  #        an IOString will be created by calling the parameter's to_s method.
  # * stdout [IO]: the IO object to receive the child's output.
  # * stderr [IO]: the IO object to receive the child's stderr.
  # * timeout [seconds]: the number of seconds to wait before killing the job.
  #
  # If `stdin`, `stdout`, or `stderr` are omitted, an empty IOString will be created.
  # If output and error are IOStrings, the [output] method will return the child's
  # stdout, and [error] will return its stderr.
  #
  # ## Examples
  #
  # * Simple invocation:            `job = Job.new pool, 'echo hi'`
  # * Redirect outpout to a file:   `Job.new pool, 'wkhtmltopdf', stdout: File.new('/tmp/out.pdf', 'w')`
  # * Passing an array and options: `Job.new pool, ['cat', '/tmp/infile', {pgroup: true}]`

  def initialize pool, command, options={}
    @start_time = Time.now
    @pool   = pool
    @killed = false
    @timed_out = false

    @stdin  = options[:stdin] || StringIO.new
    @stdin  = StringIO.new(@stdin.to_s) unless @stdin.respond_to?(:readpartial)
    @stdout = options[:stdout] || StringIO.new
    @stderr  = options[:stderr] || StringIO.new

    @chin, @chout, @cherr, @child = Open3.popen3(*command)
    @chout.binmode

    @pool._add(self)

    @thrin  = Thread.new { drain(@stdin, @chin) }
    @throut = Thread.new { drain(@chout, @stdout) }
    @threrr = Thread.new { drain(@cherr, @stderr) }

    # ensure cleanup is called when the child exits. (crazy that this requires a whole new thread!)
    @cleanup_thread = Thread.new do
      if options[:timeout]
        unless @child.join(timeout)
          @timed_out = true
          kill
        end
      else
        @child.join
      end
      stop
    end
  end

  def write *args
    @stdin.write *args
  end

  def read *args
    @stdout.read *args
  end

  def output
    @stdout.string
  end

  def error
    @stderr.string
  end

  def finished?
    @stop_time != nil
  end

  # returns false if the process hasn't finished yet
  def success?
    finished? && @child.value.success? ? true : false
  end

  def killed?
    @killed
  end

  def timed_out?
    @timed_out
  end

  # kill-o-zaps the phantom process now (using -9 if needed), then waits until it's truly gone
  def kill seconds_until_panic=2
    @killed = true
    if @child.alive?
      # rescue because process might have died between previous line and this one
      Process.kill("TERM", @child.pid) rescue Errno::ESRCH
    end
    if !@child.join(seconds_until_panic)
      Process.kill("KILL", @child.pid) if @child.alive?
    end
    # ensure kill doesn't return until process is truly gone
    # (there may be a chance of this deadlocking with a blocking callback... not sure)
    @cleanup_thread.join unless Thread.current == @cleanup_thread
  end

  # waits patiently until the process terminates, then cleans up
  def stop
    wait_for_the_end   # do all our waiting outside the sync loop
    @pool._remove(self) do
      _cleanup
    end
  end


  # only meant to be used by the ProcessMonitor
  def _child_thread
    @child
  end

  # may only be called once, synchronized by stop()
  def _cleanup
    raise "Someone else already cleaned up this job?!" if @stop_time
    @stop_time = Time.now
  end

  # returns true if process was previously active.  must be externally synchronized.
  # TODO: this is a terrible api.  gotta be a way to clean it up.
  def _deactivate
    retval = @inactive
    @inactive = true
    return !retval
  end


private
  def wait_for_the_end
    [@thrin, @throut, @threrr, @child].each(&:join)
    @cleanup_thread.join unless Thread.current == @cleanup_thread
  end

  # reads every last drop, then closes both files.  must be threadsafe.
  def drain reader, writer
    begin
      # randomly chosen buffer size
      loop { writer.write(reader.readpartial(256*1024)) }
    rescue EOFError
      # not an error
      # puts "EOF STDOUT" if reader == @chout
      # puts "EOF STDERR" if reader == @cherr
      # puts "EOF STDIN #{reader}" if writer == @chin
    rescue Errno::EPIPE
      # child was killed, no problem
    rescue StandardError => e
      @pool.log "#{e.class}: #{e.message}\n"
    ensure
      reader.close
      # writer may already be closed
      writer.close rescue Errno::EPIPE
    end
  end
end
