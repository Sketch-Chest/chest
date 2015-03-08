require 'spec_helper'

require 'zip'

class ZipFileGenerator
  # Initialize with the directory to zip and the location of the output archive.
  def initialize(inputDir, outputFile)
    @inputDir = inputDir
    @outputFile = outputFile
  end
  # Zip the input directory.
  def write()
    entries = Dir.entries(@inputDir)
    ['.', '..', '.git'].each{|e| entries.delete(e) }
    io = Zip::File.open(@outputFile, Zip::File::CREATE)
    writeEntries(entries, "", io)
    io.close()
  end
  # A helper method to make the recursion work.
  private
  def writeEntries(entries, path, io)

    entries.each do |e|
      zipFilePath = path == "" ? e : File.join(path, e)
      diskFilePath = File.join(@inputDir, zipFilePath)
      if File.directory?(diskFilePath)
        io.mkdir(zipFilePath)
        subdir =Dir.entries(diskFilePath); subdir.delete("."); subdir.delete("..")
        writeEntries(subdir, zipFilePath, io)
      else
        io.get_output_stream(zipFilePath) { |f| f.print(File.open(diskFilePath, "rb").read())}
      end
    end

  end
end

describe Chest::Connector do
  before :all do
    token = 'qlpqfi77yskT-GleSAlv9g'
    @conn = Chest::Connector.new(token, api: 'http://localhost:3000/api')
  end

  it 'can publish package' do
    Dir.chdir 'spec/fixtures/Sketch-StickyGrid'

    input_path = Dir.pwd
    puts input_path
    chest_config = JSON.parse(open(File.join(input_path, 'chest.json')).read)
    # TODO: validate plugin_name
    metadata = {
      name: chest_config['name'],
      version: chest_config['version'],
      description: chest_config['description'],
      readme: File.open(File.join(input_path, 'README.md')).read,
      homepage: chest_config['homepage'],
      repository: chest_config['repository'],
      license: chest_config['license']
    }

    archive_path = "/tmp/#{chest_config['name']}.zip"
    File.delete archive_path if File.exist? archive_path
    ZipFileGenerator.new(input_path, archive_path).write

    status = @conn.publish_package(metadata, File.new(archive_path, 'rb'))

    pp status

    expect(status).to be_a_kind_of Hash
  end

  it 'can fetch package information' do
    name = 'StickyGrid'
    info = @conn.fetch_package(name)

    pp info

    expect(info).to be_a_kind_of Hash
    expect(info).to have_key 'name'
    expect(info['name']).to eq name
  end

  # it 'can unpublish plugin' do
  #   status = @conn.unpublish_package('StickyGrid')
  #   pp status

  #   expect(status).to be_a_kind_of Hash
  # end
end
