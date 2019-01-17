require "bundler"
require "gemnasium/parser/patterns"

module Gemnasium
  module Parser
    class Podfile
      attr_reader :content

      def initialize(content)
        @content = content
      end

      def dependencies
        @dependencies ||= [].tap do |deps|
          pod_matches.each do |match|
            dep = dependency(match)
            deps << dep if dep
          end
        end
      end

      private
        def pod_matches
          @pod_matches ||= matches(Patterns::POD_CALL)
        end

        def matches(pattern)
          [].tap{|m| content.scan(pattern){ m << Regexp.last_match } }
        end

        def dependency(match)
          opts = Patterns.options(match["opts"])
          clean!(match, opts)
          name, reqs = match["name"], [match["req1"], match["req2"]].compact
          Bundler::Dependency.new(name, reqs, opts).tap do |dep|
            line = content.slice(0, match.begin(0)).count("\n") + 1
            dep.instance_variable_set(:@line, line)
          end
        end

        def groups(match)
          group = group_matches.detect{|m| in_block?(match, m) }
          group && Patterns.values(group[:grps])
        end

        def in_block?(inner, outer)
          outer.begin(:blk) <= inner.begin(0) && outer.end(:blk) >= inner.end(0)
        end

        def group_matches
          @group_matches ||= matches(Patterns::GROUP_CALL)
        end

        def git?(match, opts)
          opts["git"] || in_git_block?(match)
        end

        def github?(match, opts)
          opts["github"]
        end

        def in_git_block?(match)
          git_matches.any?{|m| in_block?(match, m) }
        end

        def git_matches
          @git_matches ||= matches(Patterns::GIT_CALL)
        end

        def path?(match, opts)
          opts["path"] || in_path_block?(match)
        end

        def in_path_block?(match)
          path_matches.any?{|m| in_block?(match, m) }
        end

        def path_matches
          @path_matches ||= matches(Patterns::PATH_CALL)
        end

        def clean!(match, opts)
          opts["group"] ||= opts.delete("groups")
          opts["group"] ||= groups(match)
          groups = Array(opts["group"]).flatten.compact
          runtime = groups.empty? || !(groups & Parser.runtime_groups).empty?
          opts["type"] ||= runtime ? :runtime : :development
        end
    end
  end
end
