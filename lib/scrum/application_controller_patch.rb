require_dependency "application_controller"

module Scrum
	module ApplicationPatch
		def self.included(base)
			base.class_eval do
				def current_user
					@current_user ||= find_current_user
				end
				helper_method :current_user
			end
		end
	end
end

