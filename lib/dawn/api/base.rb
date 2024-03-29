# Unlight
# Copyright (c) 2019 Open Unlight
# This software is released under the Apache 2.0 License.
# https://opensource.org/licenses/Apache2.0

# frozen_string_literal: true

module Dawn
  module API
    # Base API Class
    #
    # @since 0.1.0
    class Base < Grape::API
      insert_before Grape::Middleware::Error, Sentry::Rack::CaptureExceptions

      format :json
      default_format :json

      helpers Pagy::Backend
      helpers do
        def pagy_get_vars(collection, vars)
          {
            count: collection.count,
            page: params[:page],
            items: params[:per] || vars[:items] || 25
          }
        end
      end
    end
  end
end
