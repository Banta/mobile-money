module Pesapal
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path("../templates", __FILE__)

      def create_configuration
        copy_file "pesapal.yml", "config/pesapal.yml"
      end
    end
  end
end
