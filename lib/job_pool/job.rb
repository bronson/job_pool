# Fires off a child process, feeds it, and keeps track of the results.

require 'open3'
require 'tempfile'
require 'stringio'


class JobPool; end


# A job keeps track of the child process that gets forked.
# job is the Ruby data structure, process is the Unix process.
class JobPool::Job
  attr_reader :start_time, :stop_time  # start and finish times of this job
  attr_reader :inio, :outio, :errio    # fds for child's stdin/stdout/stderr

  # runs cmd, passes instr on its stdin, and fills outio and
  # errio with the command's output.
  def initialize pool, cmd, inio=nil, outio=nil, errio=nil, timeout=nil
    @start_time = Time.now
    @pool  = pool
    @inio  = inio || StringIO.new
    @inio  = StringIO.new(@inio.to_s) unless @inio.respond_to?(:readpartial)
    @outio = outio || StringIO.new
    @errio = errio || StringIO.new
    @chin, @chout, @cherr, @child = Open3.popen3(*cmd)

    @pool._add(self)
    @chout.binmode

    @killed = false
    @timed_out = false

    @thrin  = Thread.new { drain(@inio, @chin) }
    @throut = Thread.new { drain(@chout, @outio) }
    @threrr = Thread.new { drain(@cherr, @errio) }

    # ensure cleanup is called when the child exits. (crazy that this requires a whole new thread!)
    # TODO: rename me to cleanup_thread?
    @thrchild = Thread.new do
      if timeout
        # TODO: inline outatime
        outatime unless @child.join(timeout)
      else
        @child.join
      end
      stop
    end
  end

  def write *args
    @inio.write *args
  end

  def read *args
    @outio.read *args
  end

  def output
    @outio.string
  end

  def error
    @errio.string
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
    @thrchild.join unless Thread.current == @thrchild
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
    @thrchild.join unless Thread.current == @thrchild
  end

  def outatime
    @timed_out = true
    kill
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
