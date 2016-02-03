require "spec_helper"

describe Gemnasium::Parser::Podspec do
  def content(string)
    @content ||= begin
      indent = string.scan(/^[ \t]*(?=\S)/)
      n = indent ? indent.size : 0
      string.gsub(/^[ \t]{#{n}}/, "")
    end
  end

  def podspec
    @podspec ||= Gemnasium::Parser::Podspec.new(@content)
  end

  def dependencies
    @dependencies ||= podspec.dependencies
  end

  def dependency
    dependencies.size.should == 1
    dependencies.first
  end

  def reset
    @content = @podspec = @dependencies = nil
  end

  it "parses double quotes" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency "rake", ">= 0.8.7"
      end
    EOF
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "parses single quotes" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency 'rake', '>= 0.8.7'
      end
    EOF
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "ignores mixed quotes" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency "rake', ">= 0.8.7"
      end
    EOF
    dependencies.size.should == 0
  end

  it "parses pods with a period in the name" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency "pygment.rb", ">= 0.8.7"
      end
    EOF
    dependency.name.should == "pygment.rb"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "parses non-requirement pods" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency "rake"
      end
    EOF
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0"]
  end

  it "parses multi-requirement pods" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency "rake", ">= 0.8.7", "<= 0.9.2"
      end
    EOF
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == ["<= 0.9.2", ">= 0.8.7"]
  end

  it "parses single-element array requirement pods" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency "rake", [">= 0.8.7"]
      end
    EOF
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "parses multi-element array requirement pods" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency "rake", [">= 0.8.7", "<= 0.9.2"]
      end
    EOF
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == ["<= 0.9.2", ">= 0.8.7"]
  end

  it "parses runtime pods" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency "rake"
      end
    EOF
    dependencies[0].type.should == :runtime
  end

  it "records dependency line numbers" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency "rake"

        spec.dependency "rails"
      end
    EOF
    dependencies[0].instance_variable_get(:@line).should == 2
    dependencies[1].instance_variable_get(:@line).should == 4
  end

  it "parses parentheses" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency("rake", ">= 0.8.7")
      end
    EOF
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end

  it "parses pods followed by inline comments" do
    content(<<-EOF)
      Pod::Spec.new do |spec|
        spec.dependency "rake", ">= 0.8.7" # Comment
      end
    EOF
    dependency.name.should == "rake"
    dependency.requirement.as_list.should == [">= 0.8.7"]
  end
end
