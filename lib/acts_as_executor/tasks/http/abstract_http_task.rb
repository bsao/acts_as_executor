module ActsAsExecutor
  module Tasks
    module Http
      # Abstract HTTP task that establishes a connection to a specified URI
      class AbstractHttpTask
        include Java::java.util.concurrent.Callable

        attr_accessor :uri, :etag

        # Returns a HttpURLConnection[http://download.oracle.com/javase/6/docs/api/java/net/HttpURLConnection.html] or nil if an exception occurred
        def get_connection
          connection = nil
          begin          
            uri = Java::java.net.URL.new @uri

            connection = uri.open_connection
            connection.set_request_property("If-None-Match", @eta) if @etag
            connection.connect
          rescue Java::java.net.MalformedURLException
            Rails.logger.error "Unable to attempt connection to URI \"" + @uri + "\". Unknown protocol"
          rescue Java::java.io.IOException
            Rails.logger.warn "Unable to open connection to URI \"" + @uri + "\""
          rescue Java::java.net.SocketTimeoutException
            Rails.logger.warn "Unable to establish connection to URI \"" + @uri + "\". Timeout has expired"
          end
          return connection
        end
      end
    end
  end
end