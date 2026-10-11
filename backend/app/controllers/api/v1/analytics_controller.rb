module Api
  module V1
    class AnalyticsController < ApplicationController
      before_action :authenticate_user!

      # GET /api/v1/analytics/summary
      def summary
        data = CompensationAnalyticsQuery.call
        render json: {
          data: data,
          meta: {
            computed_at: Time.current.iso8601
          }
        }, status: :ok
      end
    end
  end
end
