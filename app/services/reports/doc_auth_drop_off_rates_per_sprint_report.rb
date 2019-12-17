require 'login_gov/hostdata'

module Reports
  class DocAuthDropOffRatesPerSprintReport < BaseReport
    REPORT_NAME = 'doc-auth-drop-offs-report'.freeze
    FIRST_SPRINT_DATE = '10-10-2019'.freeze

    def call
      ret = generate_report
      save_report(REPORT_NAME, ret.join)
    end

    private

    def generate_report
      date = Date.strptime(FIRST_SPRINT_DATE, '%m-%d-%Y')
      ret = []
      today_date = Time.zone.today
      generate_sprints(ret, date, today_date)
      ret
    end

    def generate_sprints(ret, date, today_date)
      while date < today_date
        transaction_with_timeout do
          start = date
          finish = date.next_day(14)
          ret << Db::DocAuthLog::DropOffRates.new.call(fmt(start), fmt(finish))
          date = finish
        end
      end
    end

    def fmt(date)
      date.strftime('%m-%d-%Y')
    end
  end
end
