require 'spec_helper'
require 'job_pool/job'

# run this to ensure there are no deadlock / process synchronization problems:
#    while rspec spec/job_pool/job_spec.rb ; do : ; done

describe JobPool::Job do
  class FakeJobPool # :nodoc:  massively oversimplified job pool used in some testing
    def initialize
      @jobs = []
    end

    def _add(job)
      @jobs << job
    end

    def _remove(job)
      yield if @jobs.delete(job)
    end

    def count
      @jobs.count
    end
  end

  let(:pool)  { FakeJobPool.new }
  let(:small_input)  { StringIO.new('small instring') }

  def time_this_block &block # :nodoc:
    start = Time.now
    block.call
    finish = Time.now
    finish - start
  end


  it "has a working drain method" do
    bigin = StringIO.new('x' * 1024 * 1024) # at least 1 MB of data to test drain loop
    job = JobPool::Job.new(pool, 'cat', stdin: bigin)
    job.stop
    expect(job.output).to eq bigin.string
    expect(job.finished?).to eq true
  end

  it "waits until a sleeping command is finished" do
    # pile a bunch of checks into this test so we only have to sleep once
    expect(pool.count).to eq 0
    claimed = nil
    job = nil

    elapsed = time_this_block do
      # echo -n doesn't work here because of platform variations
      # and for some reason jruby requires the explicit subshell; mri launches it automatically
      job = JobPool::Job.new(pool, '/bin/sh -c "sleep 0.1 && printf done."', stdin: small_input)
      expect(pool.count).to eq 1
      job.stop
      expect(job.start_time).not_to eq nil
      expect(job.stop_time).not_to eq nil
      claimed = job.stop_time - job.start_time
      expect(job.output).to eq 'done.'
      expect(job.finished?).to eq true
      expect(job.success?).to eq true
    end

    # ensure process elapsed time is in the ballpark
    expect(elapsed).to be >= 0.1
    expect(claimed).to be >= 0.1
    expect(claimed).to be <= elapsed

    expect(pool.count).to eq 0
    expect(job.stdout.closed_read?).to eq true
    expect(job.stderr.closed_read?).to eq true
  end

  it "has a working kill method" do
    job = nil
    elapsed = time_this_block do
      job = JobPool::Job.new(pool, ['sleep', '0.5'], stdin: small_input)

      expect(job.finished?).to eq false
      expect(job.killed?).to eq false
      expect(job.success?).to eq false
      expect(job.timed_out?).to eq false

      job.kill

      expect(job.finished?).to eq true
      expect(job.killed?).to eq true
      expect(job.success?).to eq false
      expect(job.timed_out?).to eq false
    end

    expect(elapsed).to be < 0.5
    expect(job.stdout.closed_read?).to eq true
    expect(job.stderr.closed_read?).to eq true
  end

  it "handles invalid commands" do
    expect {
      expect(pool.count).to eq 0
      job = JobPool::Job.new(pool, ['ThisCmdDoes.Not.Exist.'], stdin: small_input)
      raise "we shouldn't get here"
    }.to raise_error(/[Nn]o such file/)
    expect(pool.count).to eq 0
  end

  it "has a working timeout" do
    elapsed = time_this_block do
      job = JobPool::Job.new(pool, ['sleep', '10'], stdin: small_input, timeout: 0.1)
    end
    expect(elapsed).to be < 0.2
  end

  it "accepts a 0-length timeout" do
    elapsed = time_this_block do
      job = JobPool::Job.new(pool, ['sleep', '10'], stdin: small_input, timeout: 0)
    end
    expect(elapsed).to be < 0.2
  end
end
