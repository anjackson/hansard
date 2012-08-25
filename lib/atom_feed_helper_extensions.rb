module ActionView
  module Helpers #:nodoc:
    module AtomFeedHelper
      def atom_feed_with_options(options = {}, &block)
        if options[:schema_date]
          options[:schema_date] = options[:schema_date].strftime("%Y-%m-%d") if options[:schema_date].respond_to?(:strftime)
        else
          options[:schema_date] = "2005" # The Atom spec copyright date
        end
        
        xml = options[:xml] || eval("xml", block.binding)
        xml.instruct!
 
        feed_opts = {"xml:lang" => options[:language] || "en-US", "xmlns" => 'http://www.w3.org/2005/Atom'}
        feed_opts.merge!(options).reject!{|k,v| !k.to_s.match(/^xml/)}
 
        xml.feed(feed_opts) do
          xml.id("tag:#{request.host},#{options[:schema_date]}:#{request.request_uri.split(".")[0]}")
          xml.link(:rel => 'alternate', :type => 'text/html', :href => options[:root_url] || (request.protocol + request.host_with_port))
          xml.link(:rel => 'self', :type => 'application/atom+xml', :href => options[:url] || request.url)
          yield AtomFeedBuilder.new(xml, self)
        end
      end
      alias_method_chain :atom_feed, :options
    end
  end
end