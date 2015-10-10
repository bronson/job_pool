require 'thwait'

require 'job_pool/job'

# TODO: take mutex once in kill_all
# TODO: rewrite wait_next

class JobPool
  class TooManyJobsError < StandardError; end

  attr_accessor :max_jobs

  def initialize(options={})
    @mutex ||= Mutex.new

    @processes ||= []   # TODO: convert this to a hash by child thread?
    @max_jobs = options[:max_jobs]
  end

  def launch *args
    JobPool::Job.new self, *args
  end

  def first
    @mutex.synchronize { @processes.first }
  end

  def count
    @mutex.synchronize { @processes.count }
  end

  def find &block
    @mutex.synchronize { @processes.find(&block) }
  end

  def kill_all
    # TODO: this is racy...  if someone else is starting processes,
    # we'll just endless loop.  can we take the mutex once outside the loop?
    while f = first
      f.kill
    end
  end

  # blocks until any child process returns (unless nonblock is true, where it returns nil TODO)
  # raises an exception if no processes are running, or if called nonblocking
  # and no processes have finished (see ThreadsWait#next_wait for details).
  def wait_next nonblock=nil
    # we wait on child threads since calling waitpid would produce a race condition.

    threads = {}
    @processes.each { |p|
      threads[p._child_thread] = p
    }

    # TODO: test nonblock

    thread = ThreadsWait.new(threads.keys).next_wait(nonblock)
    process = threads[thread]
    process.stop # otherwise process will be in an indeterminite state
    process
  end

  # TODO: not private so jobs can add and remove themselves.  yuk!

  def _add process
    @mutex.synchronize do
      if @max_jobs && @processes.count >= @max_jobs
        raise JobPool::TooManyJobsError.new("launched process #{@processes.count+1} of #{@max_processes} maximum")
      end
      @processes.push process
    end
  end

  # removes process from process table.  pass a block that cleans up after the process.
  # _remove may be called lots of times but block will only be called once
  def _remove process
    cleanup = false

    @mutex.synchronize do
      cleanup = process._deactivate
      raise "process not in process table??" if cleanup && !@processes.include?(process)
    end

    # don't want to hold mutex when calling callback because it might block
    if cleanup
      yield
      @mutex.synchronize do
        value = @processes.delete(process)
        raise "someone else deleted process??" unless value
      end
    end
  end
end
