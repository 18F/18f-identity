module Db
  module DocAuthLog
    module DropOffRatesHelper
      STEPS = %w[welcome upload_option front_image back_image ssn verify_info doc_success phone
                 encrypt personal_key verified].freeze

      private

      attr_reader :start, :finish, :issuer, :results

      def drop_off_rates(title:, issuer: nil, start: nil, finish: nil)
        @title = title
        @issuer = issuer
        @start = start
        @finish = finish
        generate_report
      end

      def select_count_from_profiles_where_verified_and_active
        <<~SQL
          select count(*)
          from profiles
          where verified_at is not null and active=true
        SQL
      end

      def select_counts_from_doc_auth_logs
        <<~SQL
          select count(welcome_view_at) as welcome, count(upload_view_at) as upload_option,
          count(COALESCE(front_image_view_at,mobile_front_image_view_at)) as front_image,
          count(COALESCE(back_image_view_at,mobile_back_image_view_at,capture_mobile_back_image_view_at)) as back_image,
          count(ssn_view_at) as ssn,
          count(verify_view_at) as verify_info,
          count(doc_success_view_at) as doc_success,
          count(verify_phone_view_at) as phone,
          count(encrypt_view_at) as encrypt,
          count(verified_view_at) as personal_key
          from doc_auth_logs
        SQL
      end

      def at_least_one_image_submitted
        predicates = [
          'front_image_submit_count>0',
          'back_image_submit_count>0',
          'mobile_back_image_submit_count>0',
          'capture_mobile_back_image_submit_count>0',
        ].join(' or ')

        "(#{predicates})"
      end

      def oldest_ial2_date
        '01/01/2019'
      end

      def initialize_results
        @results = []
        @results << @title + (issuer ? ", issuer: #{issuer}" : '') + "\n"
        @results << "#{start} <= date user starts doc auth < #{finish}\n\n" if start || finish
      end

      def generate_report
        initialize_results
        rates = drop_offs_in_range
        verified_profiles = verified_profiles_in_range
        rates['verified'] = verified_profiles[0]['count']
        results << format("%20s %6s %3s %3s\n", 'step', 'users', '%users', 'dropoff')
        print_report(rates)
      end

      def verified_profiles_in_range
        ActiveRecord::Base.connection.execute(verified_user_counts_query)
      end

      def drop_offs_in_range
        rates = ActiveRecord::Base.connection.execute(drop_offs_query)
        rates[0]
      end

      def verified_profiles_count_for_issuer
        query = <<~SQL
          select count(*) from identities where service_provider = '#{issuer}'
        SQL
        ActiveRecord::Base.connection.execute(query)
      end

      def drop_offs_query
        <<~SQL
          #{select_counts_from_doc_auth_logs}
          where '#{start}' <= welcome_view_at and welcome_view_at < '#{finish}' and issuer='#{issuer}'
        SQL
      end

      def print_report(rates)
        STEPS.each_with_index do |step, index|
          percent_left = calc_percent_left(rates, step, STEPS[0])
          dropoff = calc_dropoff(rates, STEPS[index + 1], step)
          results << format("%20s %6d %5d%% %6d%%\n", step, rates[step], percent_left, dropoff)
        end
        results << "\n\n"
        results.join
      end

      def calc_percent_left(rec, step, total)
        return 100 unless step && total
        total = rec[total]
        return 100 if total.zero?
        ((rec[step] / total.to_f) * 100.0).round
      end

      def calc_dropoff(rec, step, total)
        return 0 unless step && total
        total = rec[total]
        return 0 if total.zero?
        ((1 - (rec[step] / total.to_f)) * 100.0).round
      end
    end
  end
end
