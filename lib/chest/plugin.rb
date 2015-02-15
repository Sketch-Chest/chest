class Chest::Plugin
  attr_reader :path, :name, :kind

  def initialize(path)
    @path = path
    @name = File.basename(path)
    @kind = guess_kind(path)
  end

  def updatable?
    @kind != :local
  end

  def update
    case @kind
    when :git
      update_git
    else
      false
    end
  end

  def update_git
    puts "Updating '#{@name}' ..."
    system "cd '#{@path}' && git pull"
  end

  private

  def guess_kind(path)
    if Dir.exist? File.join(path, '.git')
      :git
    else
      :local
    end
  end
end
