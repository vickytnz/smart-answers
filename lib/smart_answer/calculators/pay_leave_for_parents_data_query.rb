module SmartAnswer::Calculators
  class PayLeaveForParentsDataQuery
    def statutory_parental_pay
      rates.statutory_parental_pay
    end

    def start_date
      rates.start_date
    end

    def end_date
      rates.end_date
    end

  private

    def rates
      @rates ||= RatesQuery.from_file('pay_leave_for_parents').rates
    end
  end
end
