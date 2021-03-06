module Jobs
  class Mingle < Jobs::Base
    sidekiq_options queue: :low

    def execute(args = {})
      return if !SiteSetting.mingle_enabled
      return log_mismingle unless mingle_pairs.presence
      mingle_pairs.each { |pair| ::Mingle::Sender.new(pair.compact).send! }
    ensure
      ::Mingle::Scheduler.new.reschedule!
    end

    private

    def mingle_pairs
      @mingle_pairs ||= ::Mingle::Mixer.new(mingle_group).mix!
    end

    def mingle_group
      @mingle_group ||= ::Group.find_by(name: SiteSetting.mingle_group_name) || Group.new
    end

    def log_mismingle
      Rails.logger.warn "No pairs generated from Mingle, group name was '#{SiteSetting.mingle_group_name}'. Are you sure that group exists and has members in it?" if mingle_group.users.empty?
    end
  end
end
