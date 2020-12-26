module Bookstack
  module Cli
    class ConvertMarkdownToMarkdeep
      def self.call(markdown_file_blob, markdeep_options)
        markdeep_contents = markdown_file_blob.file_contents

        markdeep_contents.sub!(/^# (.*?)$/) do
          "**#{$1}**"
        end

        # Fix image syntax.
        #
        # Markdeep automatically links to images with just the plain markdown
        # image syntax of ![alttext](path), so we convert the markdown
        # link+image syntax of [![alttext](path)](path) to the other.
        markdeep_contents.gsub!(/\[!\[(.+?)\]\((.+?)\)\]\(.+?\)/) do
          "![#{$1}](#{$2})"
        end

        # Convert ``` to ~~~ since I like how ~~~ works more in Markdeep
        markdeep_contents.gsub!("```", "~~~")

        markdeep_contents = '<meta charset="utf-8">' \
          "\n\n" +
          markdeep_contents +
          "\n\n" \
          '<!-- Markdeep: --><style class="fallback">body{visibility:hidden;white-space:pre;font-family:monospace}</style><script src="markdeep.min.js" charset="utf-8"></script><script src="https://morgan3d.github.io/markdeep/latest/markdeep.min.js" charset="utf-8"></script><script>window.alreadyProcessedMarkdeep||(document.body.style.visibility="visible")</script>'

        # If not equal to markdeep, it means we're trying to specify options to
        # embed
        if markdeep_options != "markdeep"
          markdeep_contents += "<script>window.markdeepOptions=#{markdeep_options}</script>"
        end

        FileBlob.new(file_path: markdown_file_blob.file_path, file_contents: markdeep_contents)
      end
    end
  end
end
