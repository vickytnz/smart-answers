module SmartAnswer
  class MaternityPaternityCalculatorFlow < Flow
    class PaternityCalculatorFlow < Flow
      def define
        days_of_the_week = Calculators::MaternityPaternityCalculator::DAYS_OF_THE_WEEK

        ## QP0
        multiple_choice :leave_or_pay_for_adoption? do
          option :yes
          option :no

          next_node do |response|
            case response
            when 'yes'
              question :employee_date_matched_paternity_adoption?
            when 'no'
              question :baby_due_date_paternity?
            end
          end
        end

        ## QP1
        date_question :baby_due_date_paternity? do
          calculate :due_date do |response|
            response
          end

          calculate :calculator do
            Calculators::MaternityPaternityCalculator.new(due_date, 'paternity')
          end

          next_node do
            question :baby_birth_date_paternity?
          end
        end

        ## QAP1 - Paternity Adoption
        date_question :employee_date_matched_paternity_adoption? do
          calculate :matched_date do |response|
            response
          end

          calculate :calculator do
            Calculators::MaternityPaternityCalculator.new(matched_date, 'paternity_adoption')
          end

          calculate :leave_type do
            'paternity_adoption'
          end

          calculate :paternity_adoption do
            leave_type == 'paternity_adoption'
          end

          next_node do
            question :padoption_date_of_adoption_placement?
          end
        end

        ## QP2
        date_question :baby_birth_date_paternity? do
          calculate :date_of_birth do |response|
            response
          end

          calculate :calculator do
            calculator.date_of_birth = date_of_birth
            calculator
          end

          next_node do
            question :employee_responsible_for_upbringing?
          end
        end

        ## QAP2 - Paternity Adoption
        date_question :padoption_date_of_adoption_placement? do
          calculate :ap_adoption_date do |response|
            placement_date = response
            raise SmartAnswer::InvalidResponse if placement_date < matched_date
            calculator.adoption_placement_date = placement_date
            placement_date
          end

          calculate :ap_adoption_date_formatted do
            calculator.format_date_day ap_adoption_date
          end

          calculate :matched_date_formatted do
            calculator.format_date_day matched_date
          end

          next_node do
            question :padoption_employee_responsible_for_upbringing?
          end
        end

        ## QP3
        multiple_choice :employee_responsible_for_upbringing? do
          option :yes
          option :no
          save_input_as :paternity_responsible

          calculate :employment_start do
            calculator.employment_start
          end

          calculate :employment_end do
            due_date
          end

          calculate :qualifying_week_start do
            calculator.qualifying_week.first
          end

          calculate :p_notice_leave do
            calculator.notice_of_leave_deadline
          end

          next_node do |response|
            case response
            when 'yes'
              question :employee_work_before_employment_start?
            when 'no'
              outcome :paternity_not_entitled_to_leave_or_pay
            end
          end
        end

        ## QAP3 - Paternity Adoption
        multiple_choice :padoption_employee_responsible_for_upbringing? do
          option :yes
          option :no
          save_input_as :paternity_responsible

          calculate :employment_start do
            calculator.a_employment_start
          end

          calculate :employment_end do
            matched_date
          end

          calculate :qualifying_week_start do
            if leave_type == "paternity_adoption"
              calculator.adoption_matching_week_start
            else
              calculator.qualifying_week.first
            end
          end

          next_node do |response|
            case response
            when 'yes'
              question :employee_work_before_employment_start? # Combined flow
            when 'no'
              outcome :paternity_not_entitled_to_leave_or_pay
            end
          end
        end

        ## QP4 - Shared flow onwards
        multiple_choice :employee_work_before_employment_start? do
          option :yes
          option :no
          save_input_as :paternity_employment_start ## Needed only in outcome

          next_node do |response|
            case response
            when 'yes'
              question :employee_has_contract_paternity?
            when 'no'
              outcome :paternity_not_entitled_to_leave_or_pay
            end
          end
        end

        ## QP5
        multiple_choice :employee_has_contract_paternity? do
          option :yes
          option :no
          save_input_as :has_contract

          next_node do
            question :employee_on_payroll_paternity?
          end
        end

        ## QP6
        multiple_choice :employee_on_payroll_paternity? do
          option :yes
          option :no

          on_response do |response|
            calculator.on_payroll = response
          end

          calculate :leave_spp_claim_link do
            paternity_adoption ? 'adoption' : 'notice-period'
          end



          calculate :to_saturday do
            if paternity_adoption
              calculator.matched_week.last
            else
              calculator.qualifying_week.last
            end
          end

          calculate :to_saturday_formatted do
            calculator.format_date_day to_saturday
          end

          calculate :still_employed_date do
            paternity_adoption ? calculator.employment_end : date_of_birth
          end

          calculate :start_leave_hint do
            paternity_adoption ? ap_adoption_date_formatted : date_of_birth
          end

          next_node do |response|
            if response == 'yes'
              question :employee_still_employed_on_birth_date?
            elsif has_contract == 'no'
              outcome :paternity_not_entitled_to_leave_or_pay
            else
              question :employee_start_paternity?
            end
          end
        end

        ## QP7
        multiple_choice :employee_still_employed_on_birth_date? do
          option :yes
          option :no
          save_input_as :employed_dob

          next_node do |response|
            if has_contract == 'no' && response == 'no'
              outcome :paternity_not_entitled_to_leave_or_pay
            else
              question :employee_start_paternity?
            end
          end
        end

        ## QP8
        date_question :employee_start_paternity? do
          from { 2.years.ago(Date.today) }
          to { 2.years.since(Date.today) }

          save_input_as :employee_leave_start

          calculate :leave_start_date do |response|
            calculator.leave_start_date = response
            if paternity_adoption
              raise SmartAnswer::InvalidResponse if calculator.leave_start_date < ap_adoption_date
            else
              raise SmartAnswer::InvalidResponse if calculator.leave_start_date < date_of_birth
            end
            calculator.leave_start_date
          end

          calculate :notice_of_leave_deadline do
            calculator.notice_of_leave_deadline
          end

          next_node do
            question :employee_paternity_length?
          end
        end

        ## QP9
        multiple_choice :employee_paternity_length? do
          option :one_week
          option :two_weeks
          save_input_as :leave_amount

          calculate :leave_end_date do |response|
            calculator.paternity_leave_duration = response
            calculator.pay_end_date
          end

          next_node do
            if has_contract == 'yes' && (calculator.on_payroll == 'no' || employed_dob == 'no')
              outcome :paternity_not_entitled_to_leave_or_pay
            else
              question :last_normal_payday_paternity?
            end
          end
        end

        ## QP10
        date_question :last_normal_payday_paternity? do
          from { 2.years.ago(Date.today) }
          to { 2.years.since(Date.today) }

          calculate :calculator do |response|
            calculator.last_payday = response
            raise SmartAnswer::InvalidResponse if calculator.last_payday > to_saturday
            calculator
          end

          next_node do
            question :payday_eight_weeks_paternity?
          end
        end

        ## QP11
        date_question :payday_eight_weeks_paternity? do
          from { 2.years.ago(Date.today) }
          to { 2.years.since(Date.today) }

          precalculate :payday_offset do
            calculator.payday_offset
          end

          precalculate :payday_offset_formatted do
            calculator.format_date_day payday_offset
          end

          calculate :pre_offset_payday do |response|
            payday = response + 1.day
            raise SmartAnswer::InvalidResponse if payday > calculator.payday_offset
            calculator.pre_offset_payday = payday
            payday
          end

          calculate :relevant_period do
            calculator.formatted_relevant_period
          end

          next_node do
            question :pay_frequency_paternity?
          end
        end

        ## QP12
        multiple_choice :pay_frequency_paternity? do
          option :weekly
          option :every_2_weeks
          option :every_4_weeks
          option :monthly

          on_response do |response|
            calculator.pay_pattern = response
          end

          calculate :calculator do |response|
            calculator.pay_method = response
            calculator
          end

          next_node do
            question :earnings_for_pay_period_paternity?
          end
        end

        ## QP13
        money_question :earnings_for_pay_period_paternity? do
          on_response do |response|
            calculator.earnings_for_pay_period = response
          end

          save_input_as :earnings

          next_node do
            if calculator.average_weekly_earnings_under_lower_earning_limit?
              outcome :paternity_leave_and_pay
            else
              question :how_do_you_want_the_spp_calculated?
            end
          end
        end

        ## QP14
        multiple_choice :how_do_you_want_the_spp_calculated? do
          option :weekly_starting
          option :usual_paydates

          save_input_as :spp_calculation_method

          next_node do |response|
            if response == 'weekly_starting'
              outcome :paternity_leave_and_pay
            elsif calculator.pay_pattern == 'monthly'
              question :monthly_pay_paternity?
            else
              question :next_pay_day_paternity?
            end
          end
        end

        ## QP15 - Also shared with adoption calculator here onwards
        date_question :next_pay_day_paternity? do
          from { 2.years.ago(Date.today) }
          to { 2.years.since(Date.today) }
          save_input_as :next_pay_day

          calculate :calculator do |response|
            calculator.pay_date = response
            calculator
          end
          next_node do
            outcome :paternity_leave_and_pay
          end
        end

        ## QP16
        multiple_choice :monthly_pay_paternity? do
          option :first_day_of_the_month
          option :last_day_of_the_month
          option :specific_date_each_month
          option :last_working_day_of_the_month
          option :a_certain_week_day_each_month

          save_input_as :monthly_pay_method

          next_node do |response|
            if response == 'specific_date_each_month'
              question :specific_date_each_month_paternity?
            elsif response == 'last_working_day_of_the_month'
              question :days_of_the_week_paternity?
            elsif response == 'a_certain_week_day_each_month'
              question :day_of_the_month_paternity?
            elsif leave_type == 'adoption'
              outcome :adoption_leave_and_pay
            else
              outcome :paternity_leave_and_pay
            end
          end
        end

        ## QP17
        value_question :specific_date_each_month_paternity?, parse: :to_i do
          calculate :pay_day_in_month do |response|
            day = response
            raise InvalidResponse unless day > 0 && day < 32
            calculator.pay_day_in_month = day
          end

          next_node do
            if leave_type == 'adoption'
              outcome :adoption_leave_and_pay
            else
              outcome :paternity_leave_and_pay
            end
          end
        end

        ## QP18
        checkbox_question :days_of_the_week_paternity? do
          (0...days_of_the_week.size).each { |i| option i.to_s.to_sym }

          calculate :last_day_in_week_worked do |response|
            calculator.work_days = response.split(",").map(&:to_i)
            calculator.pay_day_in_week = response.split(",").sort.last.to_i
          end

          next_node do
            if leave_type == 'adoption'
              outcome :adoption_leave_and_pay
            else
              outcome :paternity_leave_and_pay
            end
          end
        end

        ## QP19
        multiple_choice :day_of_the_month_paternity? do
          option :"0"
          option :"1"
          option :"2"
          option :"3"
          option :"4"
          option :"5"
          option :"6"

          calculate :pay_day_in_week do |response|
            calculator.pay_day_in_week = response.to_i
            days_of_the_week[response.to_i]
          end

          next_node do
            question :pay_date_options_paternity?
          end
        end

        ## QP20
        multiple_choice :pay_date_options_paternity? do
          option :first
          option :second
          option :third
          option :fourth
          option :last

          calculate :pay_week_in_month do |response|
            calculator.pay_week_in_month = response
          end

          next_node do
            if leave_type == 'adoption'
              outcome :adoption_leave_and_pay
            else
              outcome :paternity_leave_and_pay
            end
          end
        end

        # Paternity outcomes
        outcome :paternity_leave_and_pay do
          precalculate :has_contract do
            has_contract
          end

          precalculate :leave_spp_claim_link do
            leave_spp_claim_link
          end

          precalculate :notice_of_leave_deadline do
            notice_of_leave_deadline
          end

          precalculate :pay_method do
            calculator.pay_method = (
              if monthly_pay_method
                if monthly_pay_method == 'specific_date_each_month' && pay_day_in_month > 28
                  'last_day_of_the_month'
                else
                  monthly_pay_method
                end
              elsif spp_calculation_method == 'weekly_starting'
                spp_calculation_method
              else
                calculator.pay_pattern
              end
            )
          end

          precalculate :above_lower_earning_limit do
            calculator.average_weekly_earnings > calculator.lower_earning_limit
          end

          precalculate :lower_earning_limit do
            sprintf("%.2f", calculator.lower_earning_limit)
          end

          precalculate :entitled_to_pay do
            above_lower_earning_limit
          end

          precalculate :pay_dates_and_pay do
            if entitled_to_pay && above_lower_earning_limit
              lines = calculator.paydates_and_pay.map do |date_and_pay|
                %(#{date_and_pay[:date].strftime('%e %B %Y')}|£#{sprintf('%.2f', date_and_pay[:pay])})
              end
              lines.join("\n")
            end
          end

          precalculate :total_spp do
            if above_lower_earning_limit
              sprintf("%.2f", calculator.total_statutory_pay)
            end
          end

          precalculate :average_weekly_earnings do
            sprintf("%.2f", calculator.average_weekly_earnings)
          end
        end

        outcome :paternity_not_entitled_to_leave_or_pay do
          precalculate :has_contract do
            has_contract
          end
          precalculate :paternity_employment_start do
            paternity_employment_start
          end
        end
      end
    end
  end
end
