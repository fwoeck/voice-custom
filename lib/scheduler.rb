RS = Rufus::Scheduler.new

module Scheduler

  def self.start
    return unless ENV['SUBSCRIBE_AMQP']


    RS.cron '50 3 * * *', overlap: false do
      Customer.wipe_old_history_entries
      puts "#{Time.now.utc} :: Wipe old customer history entries."
    end
  end
end
