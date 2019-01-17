require "spec_helper"

describe Gemnasium::Parser::Podfile do
  def content(string)
    @content ||= begin
      indent = string.scan(/^[ \t]*(?=\S)/)
      n = indent ? indent.size : 0
      string.gsub(/^[ \t]{#{n}}/, "")
    end
  end

  def podfile
    @podfile ||= Gemnasium::Parser::Podfile.new(@content)
  end

  def dependencies
    @dependencies ||= podfile.dependencies
  end

  def dependency
    dependencies.size.should == 1
    dependencies.first
  end

  def reset
    @content = @podfile = @dependencies = nil
  end

  it "parses double quotes" do
    content(%(pod "rake", ">= 0.8.7"))
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "parses single quotes" do
    content(%(pod 'rake', '>= 0.8.7'))
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "ignores mixed quotes" do
    content(%(pod "rake', ">= 0.8.7"))
    dependencies.size.should == 0
  end

  it "parses pods with a period in the name" do
    content(%(pod "pygment.rb", ">= 0.8.7"))
    dependency.name.should == "pygment.rb"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "parses non-requirement pods" do
    content(%(pod "rake"))
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0"]
  end

  it "parses multi-requirement pods" do
    content(%(pod "rake", ">= 0.8.7", "<= 0.9.2"))
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == ["<= 0.9.2", ">= 0.8.7"]
  end

  it "parses pods with options" do
    content(%(pod "rake", ">= 0.8.7", :require => false))
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "parses pods of a type" do
    content(%(pod "rake"))
    dependency.type.should == :runtime
    reset
    content(%(pod "rake", :type => :development))
    dependency.type.should == :development
  end

  it "parses pods of a group" do
    content(%(pod "rake"))
    dependency.groups.should == [:default]
    reset
    content(%(pod "rake", :group => :development))
    dependency.groups.should == [:development]
  end

  it "parses pods of multiple groups" do
    content(%(pod "rake", :group => [:development, :test]))
    dependency.groups.should == [:development, :test]
  end

  it "recognizes :groups" do
    content(%(pod "rake", :groups => [:development, :test]))
    dependency.groups.should == [:development, :test]
  end

  it "parses pods in a group" do
    content(<<-EOF)
      pod "rake"
      group :production do
        pod "pg"
      end
      group :development do
        pod "sqlite3"
      end
    EOF
    dependencies[0].groups.should == [:default]
    dependencies[1].groups.should == [:production]
    dependencies[2].groups.should == [:development]
  end

  it "parses pods in a group with parentheses" do
    content(<<-EOF)
      group(:production) do
        pod "pg"
      end
    EOF
    dependency.groups.should == [:production]
  end

  it "parses pods in multiple groups" do
    content(<<-EOF)
      group :development, :test do
        pod "sqlite3"
      end
    EOF
    dependency.groups.should == [:development, :test]
  end

  it "parses multiple pods in a group" do
    content(<<-EOF)
      group :development do
        pod "rake"
        pod "sqlite3"
      end
    EOF
    dependencies[0].groups.should == [:development]
    dependencies[1].groups.should == [:development]
  end

  it "parses multiple pods in multiple groups" do
    content(<<-EOF)
      group :development, :test do
        pod "rake"
        pod "sqlite3"
      end
    EOF
    dependencies[0].groups.should == [:development, :test]
    dependencies[1].groups.should == [:development, :test]
  end

  it "ignores h4x" do
    path = File.expand_path("../h4x.txt", __FILE__)
    content(%(pod "h4x", :require => "\#{`touch #{path}`}"))
    dependencies.size.should == 0
    begin
      File.should_not exist(path)
    ensure
      FileUtils.rm_f(path)
    end
  end

  it "ignores pods with a git option" do
    content(%(pod "rails", :git => "https://github.com/rails/rails.git"))
    dependencies.size.should == 1
  end

  it "ignores pods with a github option" do
    content(%(pod "rails", :github => "rails/rails"))
    dependencies.size.should == 1
  end

  it "ignores pods with a path option" do
    content(%(pod "rails", :path => "vendor/rails"))
    dependencies.size.should == 1
  end

  it "ignores pods in a git block" do
    content(<<-EOF)
      git "https://github.com/rails/rails.git" do
        pod "rails"
      end
    EOF
    dependencies.size.should == 1
  end

  it "ignores pods in a git block with parentheses" do
    content(<<-EOF)
      git("https://github.com/rails/rails.git") do
        pod "rails"
      end
    EOF
    dependencies.size.should == 1
  end

  it "ignores pods in a path block" do
    content(<<-EOF)
      path "vendor/rails" do
        pod "rails"
      end
    EOF
    dependencies.size.should == 1
  end

  it "ignores pods in a path block with parentheses" do
    content(<<-EOF)
      path("vendor/rails") do
        pod "rails"
      end
    EOF
    dependencies.size.should == 1
  end

  it "records dependency line numbers" do
    content(<<-EOF)
      pod "rake"

      pod "rails"
    EOF
    dependencies[0].instance_variable_get(:@line).should == 1
    dependencies[1].instance_variable_get(:@line).should == 3
  end

  it "parses parentheses" do
    content(%(pod("rake", ">= 0.8.7")))
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "parses pods followed by inline comments" do
    content(%(pod "rake", ">= 0.8.7" # Comment))
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "parses oddly quoted pods" do
    content(%(pod %q<rake>))
    dependency.name.should == "rake"
  end
end
