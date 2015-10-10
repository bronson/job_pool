require 'spec_helper'
require 'job_pool'

describe JobPool do
  # it "will add a process" do
  #   processes = JobPool.new(1)
  #   # this should not raise an exception
  #   # not using expect(...).not_to raise_exception since that eats all raised expections.
  #   processes._add(Object.new)
  # end
  #
  # it "won't launch too many processes" do
  #   processes = JobPool.new(0)
  #   expect { processes._add(Object.new) }.to raise_exception(JobPool::TooManyProcessesError)
  # end
  #
  # it "can disable the process counter" do
  #   processes = JobPool.new(-1)
  #   processes._add(Object.new)
  # end
  #
  # it "counts and kills multiple processes" do
  #   expect(JobPool.count).to eq 0
  #   process = JobPool::Job.new(['sleep', '20'], StringIO.new, StringIO.new, StringIO.new)
  #   process = JobPool::Job.new(['sleep', '20'], StringIO.new, StringIO.new, StringIO.new)
  #   process = JobPool::Job.new(['sleep', '20'], StringIO.new, StringIO.new, StringIO.new)
  #   process = JobPool::Job.new(['sleep', '20'], StringIO.new, StringIO.new, StringIO.new)
  #   expect(JobPool.count).to eq 4
  #   JobPool.first.kill
  #   expect(JobPool.count).to eq 3
  #   # can't use Array#each since calling delete in the block causes it to screw up
  #   JobPool.kill_all
  #   expect(JobPool.count).to eq 0
  # end
  #
  # it "waits for multiple processes" do
  #   expect(JobPool.count).to eq 0
  #   # these sleep durations might be too small, depends on machine load and scheduling.
  #   # if you're seeing threads finishing in the wrong order, try increasing them 10X.
  #   process1 = JobPool::Job.new(['sleep', '.3'], StringIO.new, StringIO.new, StringIO.new)
  #   process2 = JobPool::Job.new(['sleep', '.1'], StringIO.new, StringIO.new, StringIO.new)
  #   process3 = JobPool::Job.new(['sleep', '.2'], StringIO.new, StringIO.new, StringIO.new)
  #   expect(JobPool.count).to eq 3
  #
  #   child = JobPool.wait_next
  #   expect(child).to eq process2
  #   expect(child.finished?).to eq true
  #   expect(child.success?).to eq true
  #   expect(JobPool.count).to eq 2
  #
  #   child = JobPool.wait_next
  #   expect(child).to eq process3
  #   expect(JobPool.count).to eq 1
  #
  #   child = JobPool.wait_next
  #   expect(child).to eq process1
  #   expect(JobPool.count).to eq 0
  # end
  #
  # it "handles waiting for zero processes" do
  #   expect {
  #     child = JobPool.wait_next
  #   }.to raise_exception(ThreadsWait::ErrNoWaitingThread)
  # end
  #
  # it "can find a process" do
  #   processes = JobPool.new(-1)
  #   object = Object.new
  #   processes._add(object)
  #   result = processes.find { |o| o == object }
  #   expect(result).to eq object
  # end
end
