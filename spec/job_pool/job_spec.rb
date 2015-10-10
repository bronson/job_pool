require 'spec_helper'
require 'job_pool/job'

# run this to ensure there are no deadlock / process synchronization problems:
#    while rspec spec/job_pool/job_spec.rb ; do : ; done

describe JobPool::Job do
  class FakeJobPool
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
  let(:chin)  { StringIO.new('small instring') }
  let(:chout) { StringIO.new }
  let(:cherr) { StringIO.new }

  def time_this_block &block
    start = Time.now
    block.call
    finish = Time.now
    finish - start
  end


  it "has a working drain method" do
    bigin = StringIO.new('x' * 1024 * 1024) # at least 1 MB of data to test drain loop
    job = JobPool::Job.new(pool, 'cat', bigin, chout, cherr)
    job.stop
    expect(chout.string).to eq bigin.string
    expect(job.finished?).to eq true
  end

  it "waits until a sleeping command is finished" do
    # pile a bunch of checks into this test so we only have to sleep once
    expect(pool.count).to eq 0
    claimed = nil

    elapsed = time_this_block do
      # echo -n doesn't work here because of platform variations
      # and for some reason jruby requires the explicit subshell; mri launches it automatically
      process = JobPool::Job.new(pool, '/bin/sh -c "sleep 0.1 && printf done."', chin, chout, cherr)
      expect(pool.count).to eq 1
      process.stop
      expect(process.start_time).not_to eq nil
      expect(process.stop_time).not_to eq nil
      claimed = process.stop_time - process.start_time
      expect(chout.string).to eq 'done.'
      expect(process.finished?).to eq true
      expect(process.success?).to eq true
    end

    # ensure process elapsed time is in the ballpark
    expect(elapsed).to be >= 0.1
    expect(claimed).to be >= 0.1
    expect(claimed).to be <= elapsed

    expect(pool.count).to eq 0
    expect(chout.closed_read?).to eq true
    expect(cherr.closed_read?).to eq true
  end

  it "has a working kill method" do
    elapsed = time_this_block do
      process = JobPool::Job.new(pool, ['sleep', '0.5'], chin, chout, cherr)

      expect(process.finished?).to eq false
      expect(process.killed?).to eq false
      expect(process.success?).to eq false
      expect(process.timed_out?).to eq false

      process.kill

      expect(process.finished?).to eq true
      expect(process.killed?).to eq true
      expect(process.success?).to eq false
      expect(process.timed_out?).to eq false
    end

    expect(elapsed).to be < 0.5
    expect(chout.closed_read?).to eq true
    expect(cherr.closed_read?).to eq true
  end

  it "handles invalid commands" do
    expect {
      expect(pool.count).to eq 0
      process = JobPool::Job.new(pool, ['ThisCmdDoes.Not.Exist.'], chin, chout, cherr)
      raise "we shouldn't get here"
    }.to raise_error(/[Nn]o such file/)
    expect(pool.count).to eq 0
  end

  it "has a working timeout" do
    elapsed = time_this_block do
      process = JobPool::Job.new(pool, ['sleep', '10'], chin, chout, cherr, 0.1)
    end
    expect(elapsed).to be < 0.2
  end

  # TODO: should probably define exactly what happens in this case
  it "accepts a 0-length timeout" do
    elapsed = time_this_block do
      process = JobPool::Job.new(pool, ['sleep', '10'], chin, chout, cherr, 0)
    end
    expect(elapsed).to be < 0.2
  end
end
