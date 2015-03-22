require 'zip'

class ZipFileGenerator
  def initialize(inputDir, outputFile, ignoredFiles=[])
    @inputDir = inputDir
    @outputFile = outputFile
    @ignoredFiles = ignoredFiles
  end

  def write
    entries = Dir.entries(@inputDir)
    @ignoredFiles.each{|e| entries.delete(e) }
    io = Zip::File.open(@outputFile, Zip::File::CREATE)
    write_entries(entries, '', io)
    io.close
  end

  private

  def write_entries(entries, path, io)
    entries.each do |entry|
      zipFilePath = path == '' ? entry : File.join(path, entry)
      diskFilePath = File.join(@inputDir, zipFilePath)
      if File.directory?(diskFilePath)
        io.mkdir(zipFilePath)
        subdir = Dir.entries(diskFilePath)
        subdir.delete('.')
        subdir.delete('..')
        write_entries(subdir, zipFilePath, io)
      else
        io.get_output_stream(zipFilePath) { |f| f.print(File.open(diskFilePath, 'rb').read) }
      end
    end
  end

end
