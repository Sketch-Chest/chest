require 'zip'

class ZipFileGenerator
  def initialize(inputDir, outputFile, ignoredFiles=[])
    @inputDir = inputDir
    @outputFile = outputFile
    @ignoredFiles = ignoredFiles
  end

  def write()
    entries = Dir.entries(@inputDir)
    @ignoredFiles.each{|e| entries.delete(e) }
    io = Zip::File.open(@outputFile, Zip::File::CREATE)
    writeEntries(entries, "", io)
    io.close()
  end

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
