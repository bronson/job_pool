require 'spec_helper'
require 'job_pool'

describe 'README' do
  it "can do the first example" do
    pool = JobPool.new
    job = pool.launch("sleep 0.1; tr A-Za-z N-ZA-Mn-za-m", stdin: "the secrets")
    expect(job.output).to eq ''
    expect(pool.count).to eq 1
    sleep(0.2)
    expect(job.output).to eq "gur frpergf"
    expect(pool.count).to eq 0
  end

  it "can do the iostreams example" do
    pool = JobPool.new
    # can't use `expect { ... }.to output('contents').to_stdout`
    # because the test's stdout gets closed
    source = File.open('spec/contents.txt.gz')
    destination = File.open("/tmp/test-#{$$}-out.txt", 'w')
    pool.launch 'gunzip --to-stdout', stdin: source, stdout: destination
    pool.wait_next
    expect(File.read "/tmp/test-#{$$}-out.txt").to eq "contents\n"
    File.delete "/tmp/test-#{$$}-out.txt"
  end

  it "can do the killer example" do
    pool = JobPool.new
    job = pool.launch("sleep 600")
    expect(job.killed?).to eq false
    job.kill
    expect(job.killed?).to eq true
  end

  it "can do the max_jobs example" do
    pool = JobPool.new(max_jobs: 2)
    pool.launch("sleep 5")
    pool.launch("sleep 5")
    expect { pool.launch("sleep 5") }.to raise_error(JobPool::TooManyJobsError)
  end
end
