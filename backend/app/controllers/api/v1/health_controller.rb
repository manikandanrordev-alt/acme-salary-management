module Api
  module V1
    class HealthController < ApplicationController
      def show
        db_connected = begin
          ActiveRecord::Base.connection_pool.with_connection do |conn|
            conn.execute("SELECT 1")
            true
          end
        rescue StandardError
          false
        end

        render json: {
          status: db_connected ? "ok" : "degraded",
          service: "acme-salary-management-api",
          db: db_connected ? "connected" : "disconnected",
          timestamp: Time.current.iso8601
        }, status: db_connected ? :ok : :service_unavailable
      end
    end
  end
end
