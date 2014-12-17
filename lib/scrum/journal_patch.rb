require_dependency "journal"

module Scrum
  module JournalPatch
    def self.included(base)
      base.class_eval do

        before_save :avoid_journal_for_scrum_position

      private

        def avoid_journal_for_scrum_position
          result = true
          if journalized_type == "Issue" and !(Scrum::Setting.create_journal_on_pbi_position_change)
            details.delete_if{|detail| detail.prop_key == "position"}
            result = false if ((notes.nil? or notes.empty?) and (details.nil? or details.empty?))
          end
          return result
        end

      end
    end
  end
end
