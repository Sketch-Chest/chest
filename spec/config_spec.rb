require 'spec_helper'

describe Chest::Config do
  it 'can create instance' do
    Dir.mktmpdir do |tmpdir|
      path = File.join tmpdir, '.chestrc'

      config = Chest::Config.new(path)
      expect(config.to_hash).to eq({})
      config.test = 1
      expect(config.to_hash).to eq(test: 1)
      config.save
      expect(File.open(path).read.strip).to eq(config.to_json)
    end
  end
end
