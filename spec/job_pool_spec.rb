require 'spec_helper'
require 'job_pool'

describe JobPool do
  describe "job counter" do
    it "will add a job" do
      jobs = JobPool.new(max_jobs: 1)
      # this should not raise an exception
      # not using expect(...).not_to raise_exception since that eats all raised expections.
      jobs._add(Object.new)
    end

    it "won't launch too many jobs" do
      jobs = JobPool.new(max_jobs: 0)
      expect { jobs._add(Object.new) }.to raise_exception(JobPool::TooManyJobsError)
    end

    it "can disable the jobs counter" do
      jobs = JobPool.new
      jobs._add(Object.new)
    end
  end


  describe "with a pool" do
    let(:pool) { JobPool.new }

    before { expect(pool.count).to eq 0 }
    after { expect(pool.count).to eq 0 }

    it "counts and kills multiple processes" do
      pool.launch(['sleep', '20'])
      pool.launch(['sleep', '20'])
      pool.launch(['sleep', '20'])
      pool.launch(['sleep', '20'])
      expect(pool.count).to eq 4
      pool.first.kill
      expect(pool.count).to eq 3
      # can't use Array#each since calling delete in the block causes it to screw up
      pool.kill_all
    end

    it "waits for multiple processes" do
      # these sleep durations might be too small, depends on machine load and scheduling.
      # if you're seeing threads finishing in the wrong order, try increasing them 10X.
      process1 = pool.launch(['sleep', '.3'])
      process2 = pool.launch(['sleep', '.1'])
      process3 = pool.launch(['sleep', '.2'])
      expect(pool.count).to eq 3

      child = pool.wait_next
      expect(child).to eq process2
      expect(child.finished?).to eq true
      expect(child.success?).to eq true
      expect(pool.count).to eq 2

      child = pool.wait_next
      expect(child).to eq process3
      expect(pool.count).to eq 1

      child = pool.wait_next
      expect(child).to eq process1
    end

    it "handles waiting for zero processes" do
      expect {
        child = pool.wait_next
        # if I don't use a string, rdoc claims ThreadsWait is my class.  Bug?
      }.to raise_exception(Object.const_get 'ThreadsWait::ErrNoWaitingThread')
    end
  end

  it "can find a process" do
    object = Object.new
    pool = JobPool.new
    pool._add(object)
    result = pool.find { |o| o == object }
    expect(result).to eq object
  end
end
