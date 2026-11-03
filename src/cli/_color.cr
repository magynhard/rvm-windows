require "colorize"

# Per-stream styling, rather than Colorize's global STDOUT/STDERR switch.
# Crystal enables Windows virtual-terminal processing for console stdio itself.
module RvmCliColor
  def self.enabled?(io : IO) : Bool
    return false if ENV["NO_COLOR"]?.try { |value| !value.empty? }
    if force = ENV["FORCE_COLOR"]?
      return !force.in?("0", "false")
    end
    Colorize.default_enabled?(io)
  end

  def self.style(text : String, color : Symbol, io : IO = STDOUT, bold = false) : String
    return text if text.empty?
    styled = text.colorize(color).toggle(enabled?(io))
    styled = styled.bold if bold
    styled.to_s
  end

  def self.green(text : String, io : IO = STDOUT) : String
    style(text, :green, io)
  end

  def self.red(text : String, io : IO = STDOUT) : String
    style(text, :red, io)
  end

  def self.yellow(text : String, io : IO = STDOUT) : String
    style(text, :yellow, io)
  end

  def self.error(message : String, io : IO = STDERR) : String
    if match = message.match(/\A(No version given\.) Run (.+), for example: (.+)\z/)
      "#{red(match[1], io)} Run #{green(match[2], io)}, for example: #{green(match[3], io)}"
    elsif message.starts_with?("No system ruby found!")
      message.sub("No system ruby found!", red("No system ruby found!", io))
        .sub("rvm add <path>", green("rvm add <path>", io))
        .sub("rvm add C:\\Ruby-3.2.2x64", green("rvm add C:\\Ruby-3.2.2x64", io))
    else
      red(message, io)
    end
  end
end
