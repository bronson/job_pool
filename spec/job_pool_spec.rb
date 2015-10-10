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
      pool.launch(['sleep', '20'], StringIO.new, StringIO.new, StringIO.new)
      pool.launch(['sleep', '20'], StringIO.new, StringIO.new, StringIO.new)
      pool.launch(['sleep', '20'], StringIO.new, StringIO.new, StringIO.new)
      pool.launch(['sleep', '20'], StringIO.new, StringIO.new, StringIO.new)
      expect(pool.count).to eq 4
      pool.first.kill
      expect(pool.count).to eq 3
      # can't use Array#each since calling delete in the block causes it to screw up
      pool.kill_all
    end

    it "waits for multiple processes" do
      # these sleep durations might be too small, depends on machine load and scheduling.
      # if you're seeing threads finishing in the wrong order, try increasing them 10X.
      process1 = pool.launch(['sleep', '.3'], StringIO.new, StringIO.new, StringIO.new)
      process2 = pool.launch(['sleep', '.1'], StringIO.new, StringIO.new, StringIO.new)
      process3 = pool.launch(['sleep', '.2'], StringIO.new, StringIO.new, StringIO.new)
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
      }.to raise_exception(ThreadsWait::ErrNoWaitingThread)
    end
  end

  it "can find a process" do
    object = Object.new
    pool = JobPool.new
    pool._add(object)
    result = pool.find { |o| o == object }
    expect(result).to eq object
  end

  it "can do the readme example" do
    pool = JobPool.new
    input = StringIO.new("no you toucha my secrets")
    job = pool.launch("sleep 0.1; tr A-Za-z N-ZA-Mn-za-m", input)
    expect(job.output).to eq ''
    sleep(0.2)
    expect(job.output).to eq "ab lbh gbhpun zl frpergf"
  end
end
