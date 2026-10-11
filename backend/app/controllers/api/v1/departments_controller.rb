module Api
  module V1
    class DepartmentsController < ApplicationController
      before_action :authenticate_user!

      def index
        departments = Department.order(:name)
        render json: {
          data: departments.map { |d| { id: d.id, name: d.name, code: d.code } }
        }
      end
    end
  end
end
